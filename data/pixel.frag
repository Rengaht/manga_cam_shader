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
// uniform sampler2D texture;

varying vec4 vertColor;
varying vec4 vertTexCoord;


int main_char=15728622;


// in vec2 vTexCoord;
// out vec4 fragColor;
float rand(vec2 n) { 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
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


void main() {
    // Snap texture coordinates to the pixel grid
    vec2 vTexCoord = vec2(1.0-vertTexCoord.x, vertTexCoord.y);
    
    float delta=noise(vTexCoord*vec2(4.1, 2.1)+time*0.5);
    float distort=smoothstep(0.75-strength*0.5, 1.0, noise(vTexCoord*vec2(620.1, 6.87-strength*10.0)+time*(strength*10+1.2)));
    
    float pixscale=floor(distort/0.25)*strength+1.0;
    

    vec2 blockUV = floor(vTexCoord * u_resolution / (pixelSize*pixscale)) * (pixelSize*pixscale) / u_resolution;
    
    float distortx=smoothstep(0.5, 1.0, noise(blockUV*vec2(4.2,93.5)+distort*time*2.2)*2.0-1.0)*strength;
    float distorty=(smoothstep(0.5, 1.0, noise(blockUV*vec2(251.2,3.5)+time*12.2))*2.0-1.0)*strength;
    
    vec4 uflow=texture(u_flow, vec2(blockUV.x, 1.0-blockUV.y));    
    vec2 offset=vec2(distortx,distorty)*pixelSize*20.0/u_resolution;
    blockUV += offset;
    // blockUV=mod(blockUV,vec2(1.0));
    
    // offset.y*=length(uflow.xy);
    vec2 flow_offset= smoothstep(vec2(0.1), vec2(0.8),uflow.xy*5.0/u_resolution);
    
    vTexCoord+=flow_offset;
    // vTexCoord += offset;

    vec4 color = texture(u_texture, blockUV-uflow.xy*pixelSize*10.0/u_resolution);
    
    vec4 character_tex=1.0-texture(u_character, blockUV+flow_offset);

    color=mix(color, character_tex, progress);

    // draw circle pixel
    // float pix=length(blockUV*u_resolution+vec2(pixelSize/2.0)-(vTexCoord.xy)*u_resolution)<pixelSize*0.5? 1.0:0.0;
    vec2 p = mod(vTexCoord*u_resolution/(pixelSize*pixscale/2.0), 2.0) - vec2(1.0);
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
    output_color=smoothstep(vec3(0.25), vec3(0.7),output_color);


    // if(edge>threshold){
    //     gl_FragColor = vec4(1.0-output_color.rgb, 1.0);
    // }

    // title
    vec4 title_color=texture2D(u_title, vertTexCoord.xy+flow_offset);
    
    gl_FragColor = vec4((output_color.rgb + title_color.rgb*text_progress), 1.0);

    gl_FragColor*= (1.0+2.5*length(uflow.xy));
}
