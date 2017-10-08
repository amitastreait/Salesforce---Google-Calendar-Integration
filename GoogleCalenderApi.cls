public class GoogleCalenderApi {
		
		public static Boolean isAccessToken { get; set; }
		
		// Your CLient ID Here
		public Final static String consumerKey='66961230764-r1vo4jmpuigh9ijl9scgfoadnpdtpadv.apps.googleusercontent.com'; 
		// Your Client Secret Here
		public Final static String clientSecret='nmrO4RY7EGd2_9OpXx7MmX7f'; 
		
		public static String googleoAuthUrl='https://accounts.google.com/o/oauth2/auth?'; 
		// Your redirect URI here that you entered while creating the App in Google API console
		public static String redirect_uri = 'https://dreamhouse-a-dev-ed--c.ap5.visual.force.com/apex/GoogleCalenderoAuth'; 
		
		public static String calendar_Scope = 'https://www.googleapis.com/auth/calendar'; 
    	
        /* If you want to use Google Analytics OR any Other API then You just need to change the Scope 
		   According to API and every thing will be same. OR you can create a new custom one for each API 
		   so that it will be easy to maintain the access token and refresh token
		*/
    	//public static String analytics_Scope = 'https://www.googleapis.com/auth/analytics';
		
    
		/* Constructor */
		public GoogleCalenderApi(){
			
		}
		
		public PageReference authorization(){  
			
			String request_Body = googleoAuthUrl+'redirect_uri='+redirect_uri+'&response_type=code&client_id='+consumerKey+
										'&scope='+calendar_Scope+'&prompt=consent&access_type=offline&include_granted_scopes=true';
			
			/*
				String body = googleoAuthUrl+'redirect_uri='+redirect_uri+'&response_type=code&client_id='+consumerKey +
				'&scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcalendar&approval_prompt=force&access_type=offline';
			*/
			
			PageReference pr = new PageReference(request_Body); 
			return pr;
		}
		
		public static PageReference doFetchAccessToken(){ 
			
			String authCode = ApexPages.currentPage().getParameters().get('code');
			String errorMessage = '';
			
			String endPoint = 'https://www.googleapis.com/oauth2/v4/token';
			String authTokenBody = authCode;
			
			String requestTokenBody = 'code='+authCode+'&client_id='+consumerKey+'&client_secret='+
											clientSecret+'&redirect_uri='+redirect_uri+
												'&grant_type=authorization_code';
			
			Http http = new Http();
			httpRequest httpReq = new httpRequest();
			HttpResponse response = new HttpResponse();
			httpReq.setEndPoint(endPoint);
			httpReq.setBody(requestTokenBody);
			httpReq.setMethod('POST');
			try{
				response = http.send(httpReq);
				if(response.getStatuscode()==200){
					PageReference pageRef = new PageReference('/apex/GoogleCalendarActions');
                    pageRef.setRedirect(true);
					Map<String,object> TokenInfo = (Map<String,object>)JSON.deserializeUntyped(response.getBody());
					System.debug('#### TokenInfo '+TokenInfo);
					List<GoogleCalenderInfo__c> googleSettingInfoList = new List<GoogleCalenderInfo__c>();
					googleSettingInfoList = GoogleCalenderInfo__c.getAll().values();
					
					if(googleSettingInfoList.size() > 0 ){
						
						GoogleCalenderInfo__c googleSettingInfo = googleSettingInfoList[0];
						googleSettingInfo.Access_Token__c = String.valueOf(TokenInfo.get('access_token'));
						googleSettingInfo.Expire_In__c = Double.valueOf(TokenInfo.get('expires_in'));
						googleSettingInfo.Refresh_Token__c = String.valueOf(TokenInfo.get('refresh_token'));
						
						update new List<GoogleCalenderInfo__c>{googleSettingInfo};
					}else{
						
						GoogleCalenderInfo__c googleSettingInfo = new GoogleCalenderInfo__c();
						googleSettingInfo.Name = 'Google CalenderInfo';
						googleSettingInfo.Access_Token__c = String.valueOf(TokenInfo.get('access_token'));
						googleSettingInfo.Expire_In__c = Double.valueOf(TokenInfo.get('expires_in'));
						googleSettingInfo.Refresh_Token__c = String.valueOf(TokenInfo.get('refresh_token'));
						
						insert new List<GoogleCalenderInfo__c>{googleSettingInfo};
					}
                    return pageRef;
				}else{
					errorMessage = 'Unexpected Error while communicating with Google Calendar API. '
						+'Status '+response.getStatus()+' and Status Code '+response.getStatuscode();
                    return null;
				}     
			}catch(System.Exception e){
				if(String.valueOf(e.getMessage()).startsWith('Unauthorize endpoint')){
					errorMessage = 'Unauthorize endpoint: An Administer must go to Setup -> Administer -> Security Control ->'
						+' Remote Site Setting and add '+' '+ endPoint +' Endpoint';
                    return null;
				}else{
					errorMessage = 'Unexpected Error while communicating with Google Calendar API. '
						+'Status '+response.getStatus()+' and Status Code '+response.getStatuscode();
                    return null;
				}
			}  
            return null;
		}
		
		public static void doRefreshToken(){
			
			String errorMessage ='';
			
			Http http = new Http();
			HttpRequest httpReq = new HttpRequest();
			HttpResponse httpRes = new HttpResponse();
			httpReq.setEndpoint('https://www.googleapis.com/oauth2/v4/token');
			httpReq.setMethod('POST');
			httpReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');
			
			List<GoogleCalenderInfo__c> googleSettingInfoList = new List<GoogleCalenderInfo__c>();
			googleSettingInfoList = GoogleCalenderInfo__c.getAll().values();
			String refreshToken;
			if(googleSettingInfoList.size() > 0 )
					refreshToken = googleSettingInfoList[0].Refresh_Token__c;
			
			System.debug('#### refreshToken '+refreshToken);
			String refreshTokenBody = 'client_id='+consumerKey+'&client_secret='+clientSecret+'&refresh_token='+refreshToken
											+'&grant_type=refresh_token';
			System.debug('#### refreshTokenBody '+refreshTokenBody);
			
			httpReq.setBody(refreshTokenBody);
					
			try{
			   httpRes = http.send(httpReq); 
				if(httpRes.getStatusCode() == 200){
					Map<String,object> TokenInfo = (Map<String,object>)JSON.deserializeUntyped(httpRes.getBody());
                    GoogleCalenderInfo__c googleSettingInfo = googleSettingInfoList[0];
                    googleSettingInfo.Access_Token__c = String.valueOf(TokenInfo.get('access_token'));
                    googleSettingInfo.Expire_In__c = Double.valueOf(TokenInfo.get('expires_in'));
                    //googleSettingInfo.Refresh_Token__c = String.valueOf(TokenInfo.get('refresh_token'));
					System.debug('do Refresh Token '+googleSettingInfo);
                    update new List<GoogleCalenderInfo__c>{googleSettingInfo};
				}else{
					errorMessage = 'Unexpected Error while communicating with Google Calendar API. '
						+'Status '+httpRes.getStatus()+' and Status Code '+httpRes.getStatuscode();
				}
			}catch(System.Exception e){
				
				System.debug('#### Exception Executed '+e.getStackTraceString() + ' '+e.getMessage());
				if(String.valueOf(e.getMessage()).startsWith('Unauthorize endpoint')){
					errorMessage = 'Unauthorize endpoint: An Administer must go to Setup -> Administer -> Security Control ->'
						+' Remote Site Setting and add '+' '+ 'https://www.googleapis.com/oauth2/v4/token' +' Endpoint';
				}else{
					errorMessage = 'Unexpected Error while communicating with Google Calendar API. '
						+'Status '+httpRes.getStatus()+' and Status Code '+httpRes.getStatuscode();
				}
			}
		}
	}