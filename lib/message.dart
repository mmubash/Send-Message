class MessageModel {
  String? sId;
  String? conversationId;
  String? senderId;
  String? receiverId;
  String? text;
  String? type;
  String? status;
  String? createdAt;
  String? updatedAt;
  int? iV;

  MessageModel(
      {this.sId,
        this.conversationId,
        this.senderId,
        this.receiverId,
        this.text,
        this.type,
        this.status,
        this.createdAt,
        this.updatedAt,
        this.iV});

  MessageModel.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    conversationId = json['conversationId'];
    senderId = json['senderId'];
    receiverId = json['receiverId'];
    text = json['text'];
    type = json['type'];
    status = json['status'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['conversationId'] = this.conversationId;
    data['senderId'] = this.senderId;
    data['receiverId'] = this.receiverId;
    data['text'] = this.text;
    data['type'] = this.type;
    data['status'] = this.status;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    data['__v'] = this.iV;
    return data;
  }
}
