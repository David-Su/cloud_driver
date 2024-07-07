class PlayVideoState {
  String url;

  PlayVideoState(this.url);

  PlayVideoState clone() {
    return PlayVideoState(url);
  }
}
