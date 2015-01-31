package it.gianlucaiselli.sc;

import java.io.IOException;

import org.graphstream.algorithm.generator.DorogovtsevMendesGenerator;
import org.graphstream.algorithm.generator.Generator;
import org.graphstream.graph.Graph;
import org.graphstream.graph.implementations.SingleGraph;
import org.graphstream.stream.file.FileSinkGraphML;

public class main {

	public static void main(String[] args) {
		final int N_NODES = 100;		
		Generator gen = new DorogovtsevMendesGenerator();
		Graph graph = new SingleGraph("Dorogovtsev and Mendes model");
		gen.addSink(graph);
		gen.begin();  // The function begin() of generator initialize graph with 3 nodes
		for(int i=0; i < N_NODES - 3; i++)
		    gen.nextEvents();
		gen.end();
		graph.display();		
		FileSinkGraphML sink = new FileSinkGraphML();
		try {
			sink.writeAll(graph, "../../../../../graphml/GS_"+N_NODES+".xml");
		} catch (IOException ex) { System.out.println(ex); }
	}
}
