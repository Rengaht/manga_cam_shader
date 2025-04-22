// #version 150
uniform sampler2D u_texture;
uniform vec2 u_resolution;
uniform float pixelSize;
uniform float threshold;
uniform vec2 texOffset;
uniform float time;
uniform float strength;
uniform sampler2D u_flow;

uniform float progress;
uniform sampler2D u_character;

uniform sampler2D u_title;
uniform float text_progress;
uniform sampler2D u_background;

// uniform sampler2D texture;

varying vec4 vertColor;
varying vec4 vertTexCoord;


int main_char=15728622;


// in vec2 vTexCoord;
// out vec4 fragColor;
float rand(vec2 n) { 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}
float rand(float n){return fract(sin(n) * 43758.5453123);}

float noise(float p){
	float fl = floor(p);
  float fc = fract(p);
	return mix(rand(fl), rand(fl + 1.0), fc);
}


float noise(vec2 p){
	vec2 ip = floor(p);
	vec2 u = fract(p);
	u = u*u*(3.0-2.0*u);
	
	float res = mix(
		mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
		mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
	return res*res;
}


vec4 edge(vec2 vert){
    vec2 tc0 = vert.st + vec2(-texOffset.s, -texOffset.t);
    vec2 tc1 = vert.st + vec2(         0.0, -texOffset.t);
    vec2 tc2 = vert.st + vec2(+texOffset.s, -texOffset.t);
    vec2 tc3 = vert.st + vec2(-texOffset.s,          0.0);
    vec2 tc4 = vert.st + vec2(         0.0,          0.0);
    vec2 tc5 = vert.st + vec2(+texOffset.s,          0.0);
    vec2 tc6 = vert.st + vec2(-texOffset.s, +texOffset.t);
    vec2 tc7 = vert.st + vec2(         0.0, +texOffset.t);
    vec2 tc8 = vert.st + vec2(+texOffset.s, +texOffset.t);
    
    vec4 col0 = texture2D(u_texture, tc0);
    vec4 col1 = texture2D(u_texture, tc1);
    vec4 col2 = texture2D(u_texture, tc2);
    vec4 col3 = texture2D(u_texture, tc3);
    vec4 col4 = texture2D(u_texture, tc4);
    vec4 col5 = texture2D(u_texture, tc5);
    vec4 col6 = texture2D(u_texture, tc6);
    vec4 col7 = texture2D(u_texture, tc7);
    vec4 col8 = texture2D(u_texture, tc8);

    vec4 sum = 8.0 * col4 - (col0 + col1 + col2 + col3 + col5 + col6 + col7 + col8); 
    return sum;
}


float character(int n, vec2 p){
	p = floor(p*vec2(-4.0, 4.0) + 2.5);
    if (clamp(p.x, 0.0, 4.0) == p.x)
	{
        if (clamp(p.y, 0.0, 4.0) == p.y)	
		{
        	int a = int(round(p.x) + 5.0 * round(p.y));
			if (((n >> a) & 1) == 1) return 1.0;
		}	
    }
	return 0.0;
}
vec4 getFrontPixel(vec2 uv){
    vec4 color = texture2D(u_texture, uv);
    vec4 back = texture2D(u_background, uv);

    float diff=distance(color.rgb, back.rgb);
    if(diff>0.2){
        return color;
    }
    return vec4(0.0);

    // return color;
}
vec4 getCharacterPixel(vec2 uv){
    vec2 center=vec2(0.5,1.0);
    vec2 offset=(uv-center)*((1.0-text_progress)*2.0+1.0)+center;
    vec4 color = texture2D(u_character, offset);
    return 1.0-color;
}


void main() {
    // Snap texture coordinates to the pixel grid
    vec2 vTexCoord = vec2(1.0-vertTexCoord.x, vertTexCoord.y);
    vec2 discreteCoord = floor(vTexCoord * u_resolution / pixelSize/floor(sin(vertTexCoord.x*2.7+time*0.5)*3.0));
    vTexCoord.y+=time*2.0
            *strength
            *smoothstep(0.9-strength*0.8,1.0,noise(5.0*discreteCoord.x+time*0.27));
            // *smoothstep(0.5,0.7,noise(discreteCoord.y*20.1+time*3.8));
    vTexCoord.y=mod(vTexCoord.y, 1.0);
    
    float distort=smoothstep(0.5-strength*0.5, 1.0, noise(vTexCoord*vec2(160.1, 6.87-strength*10.0)+time*(strength*10+1.2)));    
    float pixscale=floor(distort/0.25)*strength+1.0;
    
    
    vec2 blockUV = floor(vTexCoord * u_resolution / (pixelSize*pixscale)) * (pixelSize*pixscale) / u_resolution;
    

    vec2 lineCoord=vec2(blockUV.x, vTexCoord.y);
    
    // glitch
    float distortx=sin(smoothstep(0.5, 1.0, noise(blockUV*vec2(4.2,293.5)*time*32.2))*10.25)*strength;
    float distorty= smoothstep(0.5, 1.0, noise(blockUV*vec2(251.2,3.5)+time*12.2))*strength;
    
    vec4 uflow=texture(u_flow, vec2(blockUV.x, 1.0-blockUV.y));    
    vec2 offset=vec2(distortx,0.0)*pixelSize*20.0/u_resolution;
    // blockUV += offset;
    // blockUV=mod(blockUV,vec2(1.0));
    
    // offset.y*=length(uflow.xy);
    vec2 flow_offset= smoothstep(vec2(0.1), vec2(0.8),uflow.xy*12.0/u_resolution);    
    vTexCoord+=flow_offset;
    // vTexCoord.y += offset.y;

    vec4 color = getFrontPixel(blockUV-uflow.xy*pixelSize*10.0/u_resolution);
    
    vec4 character_tex=getCharacterPixel(blockUV+flow_offset);

    color=mix(color, character_tex, progress);
    
    // draw circle pixel
    // float pix=length(blockUV*u_resolution+vec2(pixelSize/2.0)-(vTexCoord.xy)*u_resolution)<pixelSize*0.5? 1.0:0.0;
    vec2 p = mod(vTexCoord*u_resolution/(pixelSize/2.0), 2.0) - vec2(1.0);
    float pix=character(main_char, p);

    // gray scale
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    // add contract
    gray = (gray - 0.5) * 2.0 + 0.5;

    // float edge=length(edge(blockUV));
    
    vec3 output_color=color.rgb*pix;
    
    float discrete=1.0/4.0;
    output_color=floor(output_color/discrete)*discrete;
    // output_color=pow(output_color, vec3(2.0));
    output_color=smoothstep(vec3(0.3), vec3(0.7),output_color);


    // if(edge>threshold){
    //     gl_FragColor = vec4(1.0-output_color.rgb, 1.0);
    // }

    // title
    vec4 title_color=texture2D(u_title, vertTexCoord.xy+flow_offset);
    if(title_color.a>0){
        gl_FragColor = vec4(title_color.rgb*text_progress, 1.0);
    }else{  
        gl_FragColor = vec4((output_color.rgb + title_color.rgb*text_progress), 1.0);
    }
    // gl_FragColor*= (1.0+2.5*length(uflow.xy));
    // gl_FragColor=getFrontPixel(vertTexCoord.xy);
}
