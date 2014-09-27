import sys
import argparse
import igraph

def _read_graph(input_file_path):
  return igraph.Graph.Read(input_file_path, format='picklez')

def _write_graph(g, output_file_path):
  with open(output_file_path, 'wb') as output_file:
    g.write(output_file, format='picklez')

def _article_score(articlev):
  return len(filter(lambda v: v['type'] == 'article', articlev.neighbors(mode = igraph.IN)))

def _score_articles_by_propagation(g):
  rootv = g.vs.find(type='drug')
  for (v, depth, parentv) in g.bfsiter(rootv.index, advanced = True):
    if not v['type'] == 'article': continue
    parent_score = parentv['score'] if parentv['type'] == 'article' else 0
    v['score'] = parent_score + _article_score(v)
 
def _score_articles_individually(g):
  for v in g.vs(type='article'):
    v['score'] = _article_score(v)

def _score_neighbors_by_summing_article_scores(g):
  for neighbor_type in ['author', 'institution', 'grantagency']:
    for neighborv in g.vs(type=neighbor_type):
      sum_scores = 0
      for articlev in filter(lambda v: (v['type'] == 'article') and (v['score'] != None), neighborv.neighbors(mode = igraph.IN)):
        sum_scores += articlev['score']
      neighborv['score'] = sum_scores

def _score_neighbors_by_article_indegree(g):
  for neighbor_type in ['author', 'institution', 'grantagency']:
    for neighborv in g.vs(type=neighbor_type):
      neighborv['score'] = len(filter(lambda v: v['type'] == 'article', neighborv.neighbors(mode = igraph.IN)))

def _main(input_file_path, output_file_path, method, neighbor_scoring):
  g = _read_graph(input_file_path)

  method_func = _score_articles_by_propagation if method == 'propagate' else _score_articles_individually
  method_func(g)

  neighbor_scoring_func = _score_neighbors_by_summing_article_scores if neighbor_scoring == 'article_sum_score' else _score_neighbors_by_article_indegree
  neighbor_scoring_func(g)

  _write_graph(g, output_file_path)


def _parse_args(args):
  p = argparse.ArgumentParser()
  p.add_argument('--method', required=True, choices=['individual', 'propagate'])
  p.add_argument('--neighbor-scoring', required=True, choices=['article_score_sum', 'article_in_degree'])
  p.add_argument('input')
  p.add_argument('output')
  return p.parse_args(args)

if __name__ == '__main__':
  args_raw = sys.argv[1:]
  args = _parse_args(args_raw)
  _main(args.input, args.output, args.method, args.neighbor_scoring)
