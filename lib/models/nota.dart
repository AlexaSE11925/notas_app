class Nota {
  final int? localId;
  final int? serverId;
  final String titulo;
  final String contenido;
  final String fecha;
  final String estadoSync;

  Nota({
    this.localId,
    this.serverId,
    required this.titulo,
    required this.contenido,
    required this.fecha,
    this.estadoSync = 'synced',
  });

  Map<String, dynamic> toMap() {
    return {
      'localId': localId,
      'serverId': serverId,
      'titulo': titulo,
      'contenido': contenido,
      'fecha': fecha,
      'estadoSync': estadoSync,
    };
  }

  factory Nota.fromMap(Map<String, dynamic> map) {
    return Nota(
      localId: map['localId'],
      serverId: map['serverId'],
      titulo: map['titulo'] ?? '',
      contenido: map['contenido'] ?? '',
      fecha: map['fecha'] ?? '',
      estadoSync: map['estadoSync'] ?? 'synced',
    );
  }

  factory Nota.fromApi(Map<String, dynamic> json) {
    return Nota(
      serverId: json['id'],
      titulo: json['titulo'] ?? '',
      contenido: json['contenido'] ?? '',
      fecha: json['fecha'] ?? DateTime.now().toIso8601String(),
      estadoSync: 'synced',
    );
  }
}