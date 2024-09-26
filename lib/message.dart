class MessageModel {
  String? conversationId;
  String? senderId;
  String? receiverId;
  String? text;
  String? type;

  MessageModel(
      {
        this.conversationId,
        this.senderId,
        this.receiverId,
        this.text,
        this.type,
        });

  MessageModel.fromJson(Map<String, dynamic> json) {
    print("This is Json *****${json}");
    this.conversationId = json['conversationId'];
    this.senderId = json['senderId'];
    this.receiverId = json['receiverId'];
    this.text = json['text'];
    this.type = json['type'];

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['conversationId'] = this.conversationId;
    data['senderId'] = this.senderId;
    data['receiverId'] = this.receiverId;
    data['text'] = this.text;
    data['type'] = this.type;
    return data;
  }
}
