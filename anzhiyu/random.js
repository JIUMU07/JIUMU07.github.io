var posts=["2024/12/11/hello-world/","2024/12/11/My-friend/"];function toRandomPost(){
    pjax.loadUrl('/'+posts[Math.floor(Math.random() * posts.length)]);
  };