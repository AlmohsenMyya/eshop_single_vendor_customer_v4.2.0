class Message {
  final String? id;
  final String? fromId;
  final String? toId;
  final String? isRead;
  final String? message;
  final String? type;
  final String? media;
  final String? dateCreated;
  final String? picture;
  final String? profile;
  final String? sendersName;
  final String? groupName;
  final List<MediaFile>? mediaFiles;
  final String? text;
  final String? position;

  Message({
    this.id,
    this.fromId,
    this.toId,
    this.isRead,
    this.message,
    this.type,
    this.media,
    this.dateCreated,
    this.picture,
    this.profile,
    this.sendersName,
    this.groupName,
    this.mediaFiles,
    this.text,
    this.position,
  });

  Message copyWith({
    String? id,
    String? fromId,
    String? toId,
    String? isRead,
    String? message,
    String? type,
    String? media,
    String? dateCreated,
    String? picture,
    String? profile,
    String? sendersName,
    String? groupName,
    List<MediaFile>? mediaFiles,
    String? text,
    String? position,
  }) {
    return Message(
      id: id ?? this.id,
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      isRead: isRead ?? this.isRead,
      message: message ?? this.message,
      type: type ?? this.type,
      media: media ?? this.media,
      dateCreated: dateCreated ?? this.dateCreated,
      picture: picture ?? this.picture,
      profile: profile ?? this.profile,
      sendersName: sendersName ?? this.sendersName,
      groupName: groupName ?? this.groupName,
      mediaFiles: mediaFiles ?? this.mediaFiles,
      text: text ?? this.text,
      position: position ?? this.position,
    );
  }

  Message.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String?,
        fromId = json['from_id'] as String?,
        toId = json['to_id'] as String?,
        isRead = json['is_read'] as String?,
        message = json['message'] as String?,
        type = json['type'] as String?,
        media = json['media'] as String?,
        dateCreated = json['date_created'] as String?,
        picture = json['picture'] as String?,
        profile = json['profile'] as String?,
        sendersName = json['senders_name'] as String?,
        groupName = json['group_name'] as String?,
        mediaFiles = ((json['media_files'] ?? []) as List)
            .map((mediaFile) => MediaFile.fromJson(Map.from(mediaFile ?? {})))
            .toList(),
        text = json['text'] as String?,
        position = json['position'] as String?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'from_id': fromId,
        'to_id': toId,
        'is_read': isRead,
        'message': message,
        'type': type,
        'media': media,
        'date_created': dateCreated,
        'picture': picture,
        'profile': profile,
        'senders_name': sendersName,
        'group_name': groupName,
        'media_files': mediaFiles?.map((e) => e.toJson()).toList(),
        'text': text,
        'position': position
      };
}

class MediaFile {
  final String? id;
  final String? messageId;
  final String? userId;
  final String? originalFileName;
  final String? fileName;
  final String? fileUrl;
  final String? fileExtension;
  final String? fileSize;
  final String? dateCreated;

  MediaFile({
    this.id,
    this.messageId,
    this.userId,
    this.originalFileName,
    this.fileName,
    this.fileUrl,
    this.fileExtension,
    this.fileSize,
    this.dateCreated,
  });

  MediaFile copyWith({
    String? id,
    String? messageId,
    String? userId,
    String? originalFileName,
    String? fileName,
    String? fileUrl,
    String? fileExtension,
    String? fileSize,
    String? dateCreated,
  }) {
    return MediaFile(
      id: id ?? this.id,
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      originalFileName: originalFileName ?? this.originalFileName,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      fileExtension: fileExtension ?? this.fileExtension,
      fileSize: fileSize ?? this.fileSize,
      dateCreated: dateCreated ?? this.dateCreated,
    );
  }

  MediaFile.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String?,
        messageId = json['message_id'] as String?,
        userId = json['user_id'] as String?,
        originalFileName = json['original_file_name'] as String?,
        fileName = json['file_name'] as String?,
        fileUrl = json['file_url'] as String?,
        fileExtension = json['file_extension'] as String?,
        fileSize = json['file_size'] as String?,
        dateCreated = json['date_created'] as String?;

  Map<String, dynamic> toJson() => {
        'id': id,
        'message_id': messageId,
        'user_id': userId,
        'original_file_name': originalFileName,
        'file_name': fileName,
        'file_url': fileUrl,
        'file_extension': fileExtension,
        'file_size': fileSize,
        'date_created': dateCreated
      };
}
