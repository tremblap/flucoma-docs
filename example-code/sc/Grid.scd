
STRONG::A didactic example::

code::

/// make a simple grid of numbers
~simple = Dictionary.newFrom(36.collect{|i|[i.asSymbol, [i.mod(9), i.div(9)]]}.flatten(1));

//look at it
(
w = Window("the source", Rect(128, 64, 230, 100));
w.drawFunc = {
	Pen.use {
		~simple.keysValuesDo{|key, val|
			Pen.stringCenteredIn(key, Rect((val[0] * 25), (val[1] * 25), 25, 25), Font( "Helvetica", 12 ), Color.black)
		}
	}
};
w.refresh;
w.front;
)


//load it in a dataset
~raw = FluidDataSet(s);
~raw.load(Dictionary.newFrom([\cols, 2, \data, ~simple]));

// make a grid out of it
~grid = FluidGrid(s);
~gridified = FluidDataSet(s);
~grid.fitTransform(~raw, ~gridified, action:{~gridified.dump{|x| ~gridifiedDict = x["data"]; \gridded.postln;}})

// watch the grid
(
w = Window("a perspective", Rect(358, 64, 350, 230));
w.drawFunc = {
	Pen.use {
		~gridifiedDict.keysValuesDo{|key, val|
			Pen.stringCenteredIn(key, Rect((val[0] * 25), (val[1] * 25), 25, 25), Font( "Helvetica", 12 ), Color.black)
		}
	}
};
w.refresh;
w.front;
)

// change the constraints and draw again
(
~grid.axis_(0).extent_(4).fitTransform(~raw, ~gridified, action:{
	~gridified.dump{|x|
		~gridifiedDict = x["data"];\gridded.postln;
		{w.refresh;}.defer;
}})
)

// here we constrain in the other dimension
(
~grid.axis_(1).extent_(3).fitTransform(~raw, ~gridified, action:{
	~gridified.dump{|x|
		~gridifiedDict = x["data"];\gridded.postln;
		{w.refresh;}.defer;
}})
)

::

STRONG::A more colourful example exploring oversampling::

code::

// make all dependencies
(
~raw = FluidDataSet(s);
~standardized = FluidDataSet(s);
~reduced = FluidDataSet(s);
~normalized = FluidDataSet(s);
~standardizer  = FluidStandardize(s);
~normalizer = FluidNormalize(s, 0.05, 0.95);
~umap = FluidUMAP(s).numDimensions_(2).numNeighbours_(5).minDist_(0.2).iterations_(50).learnRate_(0.2);
~grid = FluidGrid(s);
~gridified = FluidDataSet(s);
)

// build a dataset of 400 points in 3D (colour in RGB)
~colours = Dictionary.newFrom(400.collect{|i|[("entry"++i).asSymbol, 3.collect{1.0.rand}]}.flatten(1));
~raw.load(Dictionary.newFrom([\cols, 3, \data, ~colours]));

//First standardize our DataSet, then apply the UMAP to get 2 dimensions, then normalise these 2 for drawing in the full window size
(
~standardizer.fitTransform(~raw,~standardized,action:{"Standardized".postln});
~umap.fitTransform(~standardized,~reduced,action:{"Finished UMAP".postln});
~normalizer.fitTransform(~reduced,~normalized,action:{"Normalized Output".postln});
)
//we recover the reduced dataset
~normalized.dump{|x| ~normalizedDict = x["data"]};

//Visualise the 2D projection of our original 4D data
(
w = Window("a perspective", Rect(128, 64, 200, 200));
w.drawFunc = {
	Pen.use {
		~normalizedDict.keysValuesDo{|key, val|
			Pen.fillColor = Color.new(~colours[key.asSymbol][0], ~colours[key.asSymbol][1],~colours[key.asSymbol][2]);
			Pen.fillOval(Rect((val[0] * 200), (val[1] * 200), 5, 5));
			~colours[key.asSymbol].flat;
		}
	}
};
w.refresh;
w.front;
)

//Force the UMAP-reduced dataset into a grid, normalise for viewing then print in another window
(
~grid.fitTransform(~reduced,~gridified,action:{"Gridded Output".postln;
	~normalizer.fitTransform(~gridified,~normalized,action:{"Normalized Output".postln;
		~normalized.dump{|x|
			~normalizedDict = x["data"];
			{
				y = Window("a grid", Rect(328, 64, 200, 200));
				y.drawFunc = {
					Pen.use {
						~normalizedDict.keysValuesDo{|key, val|
							Pen.fillColor = Color.new(~colours[key.asSymbol][0], ~colours[key.asSymbol][1],~colours[key.asSymbol][2]);
							Pen.fillOval(Rect((val[0] * 200), (val[1] * 200), 5, 5));
							~colours[key.asSymbol].flat;
						}
					}
				};
				y.refresh;
				y.front;
			}.defer;
		};
	});
});
)

// We can check the dimensions of the yielded grid by dumping the normalisation.The grid coordinates are zero-counting
~normalizer.dump{|x|x["data_max"].postln}

// This looks ok, but let's improve it with oversampling
(
~grid.oversample_(3).fitTransform(~reduced,~gridified,action:{"Gridded Output".postln;
	~normalizer.fitTransform(~gridified,~normalized,action:{"Normalized Output".postln;
		~normalized.dump{|x|
			~normalizedDict = x["data"];
			{
				y.refresh;
			}.defer;
		};
	});
});
)

// Again, checking the normalisation dump to check the maxima of each dimension
~normalizer.dump{|x|x["data_max"].postln}

::