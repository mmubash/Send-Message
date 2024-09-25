class GetUsers {
  String? sId;
  String? name;
  String? username;
  String? email;
  int? iV;

  GetUsers({this.sId, this.name, this.username, this.email, this.iV});

  GetUsers.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    name = json['name'];
    username = json['username'];
    email = json['email'];
    iV = json['__v'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['_id'] = this.sId;
    data['name'] = this.name;
    data['username'] = this.username;
    data['email'] = this.email;
    data['__v'] = this.iV;
    return data;
  }
}
