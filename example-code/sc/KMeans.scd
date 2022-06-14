code::

(
//Make some clumped 2D points and place into a DataSet
~points = (4.collect{
		       64.collect{(1.sum3rand) + [1,-1].choose}.clump(2)
	       }).flatten(1) * 0.5;
fork{
    ~dataSet =  FluidDataSet(s);
    d = Dictionary.with(
        *[\cols -> 2,\data -> Dictionary.newFrom(
			~points.collect{|x, i| [i, x]}.flatten)]);
    s.sync;
    ~dataSet.load(d, {~dataSet.print});
}
)


// Create a KMeans instance and a LabelSet for the cluster labels in the server
~clusters = FluidLabelSet(s);
~kmeans = FluidKMeans(s);

// Fit into 4 clusters
(
~kmeans.fitPredict(~dataSet,~clusters,action: {|c|
		"Fitted.\n # Points in each cluster:".postln;
		c.do{|x,i|
			("Cluster" + i + "->" + x.asInteger + "points").postln;
		}
	});
)

// Cols of kmeans should match DataSet, size is the number of clusters

~kmeans.cols;
~kmeans.size;
~kmeans.dump;

// Retrieve labels of clustered points
(
~assignments = Array.new(128);
fork{
    128.do{ |i|
        ~clusters.getLabel(i,{|clusterID|
            (i.asString+clusterID).postln;
            ~assignments.add(clusterID)
        });
        s.sync;
    }
}
)

//or faster by sorting the IDs
~clusters.dump{|x|~assignments = x.at("data").atAll(x.at("data").keys.asArray.sort{|a,b|a.asInteger < b.asInteger}).flatten.postln;}

//Visualise: we're hoping to see colours neatly mapped to quandrants...
(
d = ((~points + 1) * 0.5).flatten(1).unlace;
w = Window("scatter", Rect(128, 64, 200, 200));
~colours = [Color.blue,Color.red,Color.green,Color.magenta];
w.drawFunc = {
	Pen.use {
		d[0].size.do{|i|
			var x = (d[0][i]*200);
			var y = (d[1][i]*200);
			var r = Rect(x,y,5,5);
			Pen.fillColor = ~colours[~assignments[i].asInteger];
			Pen.fillOval(r);
		}
	}
};
w.refresh;
w.front;
)

// single point transform on arbitrary value
~inbuf = Buffer.loadCollection(s,0.5.dup);
~kmeans.predictPoint(~inbuf,{|x|x.postln;});
::

subsection:: Accessing the means

We can get and set the means for each cluster, their centroid.

code::
// with the dataset and kmeans generated and trained in the code above
~centroids = FluidDataSet(s);
~kmeans.getMeans(~centroids, {~centroids.print});

// We can also set them to arbitrary values to seed the process
~centroids.load(Dictionary.newFrom([\cols, 2, \data, Dictionary.newFrom([\0, [0.5,0.5], \1, [-0.5,0.5], \2, [0.5,-0.5], \3, [-0.5,-0.5]])]));
~centroids.print
~kmeans.setMeans(~centroids, {~kmeans.predict(~dataSet,~clusters,{~clusters.dump{|x|var count = 0.dup(4); x["data"].keysValuesDo{|k,v|count[v[0].asInteger] = count[v[0].asInteger] + 1;};count.postln}})});

// We can further fit from the seeded means
~kmeans.fit(~dataSet)
// then retreive the improved means
~kmeans.getMeans(~centroids, {~centroids.print});
//subtle in this case but still.. each quadrant is where we seeded it.
::

subsection:: Cluster-distance Space

We can get the euclidian distance of a given point to each cluster. This is often referred to as the cluster-distance space as it creates new dimensions for each given point, one distance per cluster.

code::
// with the dataset and kmeans generated and trained in the code above
b = Buffer.sendCollection(s,[0.5,0.5])
c = Buffer(s)

// get the distance of our given point (b) to each cluster, thus giving us 4 dimensions in our cluster-distance space
~kmeans.transformPoint(b,c,{|x|x.query;x.getn(0,x.numFrames,{|y|y.postln})})

// we can also transform a full dataset
~srcDS = FluidDataSet(s)
~cdspace = FluidDataSet(s)
// make a new dataset with 4 points
~srcDS.load(Dictionary.newFrom([\cols, 2, \data, Dictionary.newFrom([\pp, [0.5,0.5], \np, [-0.5,0.5], \pn, [0.5,-0.5], \nn, [-0.5,-0.5]])]));
~kmeans.transform(~srcDS, ~cdspace, {~cdspace.print})
::

subsection:: Queries in a Synth

This is the equivalent of predictPoint, but wholly on the server

code::
(
{
    var trig = Impulse.kr(5);
    var point = WhiteNoise.kr(1.dup);
    var inputPoint = LocalBuf(2);
    var outputPoint = LocalBuf(1);
    Poll.kr(trig, point, [\pointX,\pointY]);
    point.collect{ |p,i| BufWr.kr([p],inputPoint,i)};
    ~kmeans.kr(trig,inputPoint,outputPoint);
    Poll.kr(trig,BufRd.kr(1,outputPoint,0,interpolation:0),\cluster);
}.play;
)

// to sonify the output, here are random values alternating quadrant, generated more quickly as the cursor moves rightwards
(
{
	var trig = Impulse.kr(MouseX.kr(0,1).exprange(0.5,ControlRate.ir / 2));
	var step = Stepper.kr(trig,max:3);
	var point = TRand.kr(-0.1, [0.1, 0.1], trig) + [step.mod(2).linlin(0,1,-0.6,0.6),step.div(2).linlin(0,1,-0.6,0.6)] ;
    var inputPoint = LocalBuf(2);
    var outputPoint = LocalBuf(1);
	point.collect{|p,i| BufWr.kr([p],inputPoint,i)};
    ~kmeans.kr(trig,inputPoint,outputPoint);
    SinOsc.ar((BufRd.kr(1,outputPoint,0,interpolation:0) + 69).midicps,mul: 0.1);
}.play;
)

::