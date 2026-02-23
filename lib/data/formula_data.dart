class Formula {
  final String title;
  final String formula;
  final String description;
  final String category;

  const Formula({
    required this.title,
    required this.formula,
    required this.description,
    required this.category,
  });
}

const List<Formula> importantFormulas = [
  // Physics & Laws
  Formula(
    title: 'ボイルの法則',
    formula: 'P × V = 一定',
    description: '温度が一定のとき、気体の体積(V)は圧力(P)に反比例する。',
    category: '物理',
  ),
  Formula(
    title: 'シャルルの法則',
    formula: 'V / T = 一定',
    description: '圧力が一定のとき、気体の体積(V)は絶対温度(T)に比例する。',
    category: '物理',
  ),
  Formula(
    title: 'ボイル・シャルルの法則',
    formula: '(P × V) / T = 一定',
    description: '一般的に気体の圧力(P)・体積(V)・絶対温度(T)の関係を表す。',
    category: '物理',
  ),
  Formula(
    title: 'アルキメデスの原理',
    formula: 'F = ρ × V × g',
    description: '流体中の物体は、その物体が押しのけた流体の重さに等しい大きさの浮力(F)を受ける。',
    category: '物理',
  ),
  Formula(
    title: '絶対圧力',
    formula: '絶対圧力 = ゲージ圧力 + 大気圧',
    description: 'ゲージ圧力は大気圧を0とした圧力、絶対圧力は真空を0とした圧力。',
    category: '物理',
  ),
  Formula(
    title: '水圧',
    formula: 'P = 0.1 × h （気圧換算）',
    description: '水深 h (m) ごとに水圧は約 0.1 気圧（0.01 MPa）増加する。',
    category: '物理',
  ),

  // Physiology & Calculation
  Formula(
    title: '空気消費量の計算',
    formula: '消費量 = 分時換気量 × 時間 × その深度の絶対圧力',
    description: '潜水時に消費する空気の量は、深度（圧力）に比例して増加する。',
    category: '生理・計算',
  ),
  Formula(
    title: '無限圧潜水時間の目安',
    formula: '深度が深くなるほど短くなる',
    description: '減圧症を防ぐため、浮上一時停止なしで潜水できる限界の時間。',
    category: '生理',
  ),
  Formula(
    title: '酸素分圧',
    formula: 'PO2 = 全圧 × 酸素濃度(%)',
    description: '酸素中毒を防ぐため、酸素分圧(PO2)が1.4〜1.6気圧を超えないように注意する。',
    category: '生理',
  ),
];
