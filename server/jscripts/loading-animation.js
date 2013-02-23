// JavaScript Document
var LoadingAnimation = {
	text: "Loading...",
	text_idx: 1,
	text_wait_time: 0,
	wait_time: 10,
	cls: 'body',
	interval: null,
	interval_function: function() {
		s = $(".loading-animation #sprite");
		x = parseInt(s.css('left'));
		y = parseInt(s.css('top'));
		w = parseInt(s.css('width'));
		h = parseInt(s.css('height'));
		c = s.css('background-color');
		str = "no matrix";
		// Matrix 1
		if(y < 32 && 
		   h < 32 && 
		   x < 32 && 
		   w < 32)
		{
			x++;
			w--;
			y--;
			h++;	
			str = "matrix 1";
			c = "#"+(y*8).toString(16)+(h*8).toString(16)+(w*8).toString(16);
		}
		
		// Matrix 2 
		if(y < 32 && h <= 32 && x == 32 && w < 32)
		{
			w++;
			y++;
			h--;
			str="matrix 2";
			c = "#"+(y*8).toString(16)+(h*8).toString(16)+(w*8).toString(16);
		}
		
		// Matrix 3 
		if(y == 32 && h < 32 && x == 32 && w <= 32)
		{
			w--;
			h++;
			if(h==32) {x--;}
			str="matrix 3";
			c = "#"+(y*8).toString(16)+(h*8).toString(16)+(w*8).toString(16);
		}
		
		// Matrix 4 
		if(y == 32 && h <= 32 && x < 32 && w < 32)
		{
			w++;
			x--;
			h--;
			if(x==0) {y=31;x=1;w=31;h=1}
			str="matrix 4";
			c = "#"+(x*8).toString(16)+(h*8).toString(16)+(w*8).toString(16);
		}
//					$('#out').html("left(x): "+String(x)+"<br>top(y): "+String(y)+"<br>width: "+String(w)+"<br>height: "+String(h)+"<br>"+str);
		s.css('left', String(x) + "px");
		s.css('top', String(y) + "px");
		s.css('width', String(w) + "px");
		s.css('height', String(h) + "px");
		s.css('background-color', c);
		
		if(LoadingAnimation.text_wait_time > LoadingAnimation.wait_time)
		{
			$('.loading-animation #text').html(LoadingAnimation.text.substr(0,LoadingAnimation.text_idx));
			LoadingAnimation.text_idx += 1;
			if(LoadingAnimation.text_idx > LoadingAnimation.text.length) LoadingAnimation.text_idx = 1;
			LoadingAnimation.text_wait_time = 0;
		}
		else
		{
			LoadingAnimation.text_wait_time += 1;
		}
	},
	create: function(cls, time, text, text_wait){
		this.text = text;
		this.text_idx = 1;
		this.text_wait_time = 0;
		this.wait_time = text_wait;
		this.cls = cls;
		
		w = $(window).width();
		h = $(window).height();
		l = (w/2)-32;
		t = (h/2)-32;
		if($('.loading-animation').length > 0)
		{
			this.destroy();
		}
		$(cls).append("<div style=\"position:absolute;left:500px;top:200px;\">"+
					  "<div class=\"loading-animation\"><div id=\"sprite\"></div>"+
					  "<div id=\"text\"></div></div></div>");
		$('.loading-animation').css('left', String(l)+"px");
		$('.loading-animation').css('top', String(t)+"px");
		
	   this.interval = setInterval(this.interval_function, time);
	},
	destroy: function(){
		clearInterval(this.interval);
		$('.loading-animation').remove();
	}
};