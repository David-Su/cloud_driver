class BaseEntity<T> {
  String code;
  String message;
  T? result;

  BaseEntity(this.code, this.message, this.result);

}
