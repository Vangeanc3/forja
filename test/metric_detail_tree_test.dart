import 'package:flutter_test/flutter_test.dart';
import 'package:forja/domain/entities/progress_area_entity.dart';
import 'package:forja/domain/services/metric_detail_tree.dart';

void main() {
  test('agrupa tópicos selecionados preservando os dados originais', () {
    const substantivo = MetricDetailEntity(
      id: 'substantivo',
      title: 'Substantivo',
      description: 'Nomeia seres e coisas',
      type: MetricDetailType.concept,
    );
    const verbo = MetricDetailEntity(
      id: 'verbo',
      title: 'Verbo',
      description: 'Indica ação, estado ou fenômeno',
      type: MetricDetailType.concept,
      items: [
        MetricDetailEntity(
          id: 'tempos-verbais',
          title: 'Tempos verbais',
          description: 'Presente, pretérito e futuro',
        ),
      ],
    );
    const crase = MetricDetailEntity(
      id: 'crase',
      title: 'Crase',
      description: 'Fusão de preposição e artigo',
    );

    final grouped = MetricDetailTree.groupIntoParent(
      details: const [substantivo, verbo, crase],
      parent: const MetricDetailEntity(
        id: 'classes-palavras',
        title: 'Classes de palavras',
        description: 'Grupo principal',
      ),
      selectedIds: const {'substantivo', 'verbo'},
      index: 0,
    );

    expect(grouped.map((detail) => detail.id), ['classes-palavras', 'crase']);
    expect(grouped.first.items.map((detail) => detail.id), [
      'substantivo',
      'verbo',
    ]);
    expect(identical(grouped.first.items.first, substantivo), isTrue);
    expect(identical(grouped.first.items.last, verbo), isTrue);
    expect(grouped.first.items.last.items.single.id, 'tempos-verbais');
  });

  test('move um tópico para dentro de outro sem recriar o item', () {
    const substantivo = MetricDetailEntity(
      id: 'substantivo',
      title: 'Substantivo',
      description: 'Nomeia seres e coisas',
    );
    const classes = MetricDetailEntity(
      id: 'classes-palavras',
      title: 'Classes de palavras',
      description: '',
    );

    final moved = MetricDetailTree.move(
      details: const [classes, substantivo],
      detailId: 'substantivo',
      parentId: 'classes-palavras',
    );

    expect(moved, hasLength(1));
    expect(moved.single.id, 'classes-palavras');
    expect(moved.single.items.single.id, 'substantivo');
    expect(identical(moved.single.items.single, substantivo), isTrue);
  });

  test('move vários tópicos para dentro de outro preservando ordem e ids', () {
    const classes = MetricDetailEntity(
      id: 'classes-palavras',
      title: 'Classes de palavras',
      description: '',
    );
    const substantivo = MetricDetailEntity(
      id: 'substantivo',
      title: 'Substantivo',
      description: 'Nomeia seres e coisas',
    );
    const verbo = MetricDetailEntity(
      id: 'verbo',
      title: 'Verbo',
      description: 'Indica ação',
    );
    const crase = MetricDetailEntity(
      id: 'crase',
      title: 'Crase',
      description: '',
    );

    final moved = MetricDetailTree.moveMany(
      details: const [classes, substantivo, verbo, crase],
      detailIds: const {'substantivo', 'verbo'},
      parentId: 'classes-palavras',
    );

    expect(moved.map((detail) => detail.id), ['classes-palavras', 'crase']);
    expect(moved.first.items.map((detail) => detail.id), [
      'substantivo',
      'verbo',
    ]);
    expect(identical(moved.first.items.first, substantivo), isTrue);
    expect(identical(moved.first.items.last, verbo), isTrue);
  });

  test('impede mover vários tópicos para um destino selecionado', () {
    const classes = MetricDetailEntity(
      id: 'classes-palavras',
      title: 'Classes de palavras',
      description: '',
    );
    const substantivo = MetricDetailEntity(
      id: 'substantivo',
      title: 'Substantivo',
      description: '',
    );

    expect(
      () => MetricDetailTree.moveMany(
        details: const [classes, substantivo],
        detailIds: const {'classes-palavras', 'substantivo'},
        parentId: 'classes-palavras',
      ),
      throwsArgumentError,
    );
  });

  test('move um sub-tópico de volta para a lista principal', () {
    const substantivo = MetricDetailEntity(
      id: 'substantivo',
      title: 'Substantivo',
      description: 'Nomeia seres e coisas',
    );
    const classes = MetricDetailEntity(
      id: 'classes-palavras',
      title: 'Classes de palavras',
      description: '',
      items: [substantivo],
    );

    final moved = MetricDetailTree.move(
      details: const [classes],
      detailId: 'substantivo',
      parentId: null,
    );

    expect(moved.map((detail) => detail.id), [
      'classes-palavras',
      'substantivo',
    ]);
    expect(moved.first.items, isEmpty);
    expect(identical(moved.last, substantivo), isTrue);
  });

  test('edita e remove tópicos aninhados por id', () {
    const substantivo = MetricDetailEntity(
      id: 'substantivo',
      title: 'Substantivo',
      description: 'Nomeia seres e coisas',
    );
    const verbo = MetricDetailEntity(
      id: 'verbo',
      title: 'Verbo',
      description: 'Indica ação',
    );
    const classes = MetricDetailEntity(
      id: 'classes-palavras',
      title: 'Classes de palavras',
      description: '',
      items: [substantivo, verbo],
    );

    final replaced = MetricDetailTree.replace(
      details: const [classes],
      detailId: 'verbo',
      replacement: verbo.copyWith(description: 'Indica ação, estado ou fato'),
    );
    final updatedVerbo = replaced.single.items.last;

    expect(updatedVerbo.id, 'verbo');
    expect(updatedVerbo.description, 'Indica ação, estado ou fato');

    final removed = MetricDetailTree.remove(
      details: replaced,
      detailId: 'substantivo',
    );

    expect(removed.removed.id, 'substantivo');
    expect(removed.details.single.items.map((detail) => detail.id), ['verbo']);
  });

  test('impede mover um tópico para dentro de um sub-tópico dele', () {
    const classes = MetricDetailEntity(
      id: 'classes-palavras',
      title: 'Classes de palavras',
      description: '',
      items: [
        MetricDetailEntity(
          id: 'substantivo',
          title: 'Substantivo',
          description: '',
        ),
      ],
    );

    expect(
      () => MetricDetailTree.move(
        details: const [classes],
        detailId: 'classes-palavras',
        parentId: 'substantivo',
      ),
      throwsArgumentError,
    );
  });

  test('desagrupa filhos mantendo pai e filhos na lista principal', () {
    const substantivo = MetricDetailEntity(
      id: 'substantivo',
      title: 'Substantivo',
      description: 'Nomeia seres e coisas',
    );
    const verbo = MetricDetailEntity(
      id: 'verbo',
      title: 'Verbo',
      description: 'Indica ação',
    );
    const classes = MetricDetailEntity(
      id: 'classes-palavras',
      title: 'Classes de palavras',
      description: '',
      items: [substantivo, verbo],
    );
    const crase = MetricDetailEntity(
      id: 'crase',
      title: 'Crase',
      description: '',
    );

    final ungrouped = MetricDetailTree.ungroup(
      details: const [classes, crase],
      parentId: 'classes-palavras',
    );

    expect(ungrouped.map((detail) => detail.id), [
      'classes-palavras',
      'substantivo',
      'verbo',
      'crase',
    ]);
    expect(ungrouped.first.items, isEmpty);
    expect(identical(ungrouped[1], substantivo), isTrue);
    expect(identical(ungrouped[2], verbo), isTrue);
  });

  test('compara conteúdo aninhado em listas de tópicos', () {
    const first = [
      MetricDetailEntity(
        id: 'classes-palavras',
        title: 'Classes de palavras',
        description: '',
        items: [
          MetricDetailEntity(
            id: 'substantivo',
            title: 'Substantivo',
            description: '',
          ),
        ],
      ),
    ];
    const second = [
      MetricDetailEntity(
        id: 'classes-palavras',
        title: 'Classes de palavras',
        description: '',
        items: [
          MetricDetailEntity(
            id: 'substantivo',
            title: 'Substantivo comum',
            description: '',
          ),
        ],
      ),
    ];

    expect(MetricDetailTree.deepEquals(first, first), isTrue);
    expect(MetricDetailTree.deepEquals(first, second), isFalse);
  });
}
