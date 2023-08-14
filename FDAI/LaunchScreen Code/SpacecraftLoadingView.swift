//
//  SpacecraftLoadingView.swift
//  MissionOrion2
//
//  Created by James Hillhouse IV on 2/12/23.
//

import SwiftUI




struct SpacecraftLoadingView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var launchScreenManaager: LaunchScreenManager

    
    var body: some View {
        
        ZStack {

            Rectangle()
                .fill(colorScheme == .light ? .white : .black)
                .edgesIgnoringSafeArea(.all)
                .opacity(!launchScreenManaager.animateLoadViewFade ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.5), value: launchScreenManaager.animateLoadViewFade)

            // MARK: Note about using images as a background during asset loading.
            //
            // I could have used an overlay if I wanted to cover the whole screen. Were it not for the info boxes in MissionOrion,
            // this is the option that I likely would have chosen. To use overlay, see this excellent StackOverflow post by
            // @aheze,
            // https://stackoverflow.com/questions/57593552/swiftui-prevent-image-from-expanding-view-rect-outside-of-screen-bounds
            //
            Image("fdaiLaunchScreen")
                .resizable()
                .edgesIgnoringSafeArea(.all)
                .opacity(!launchScreenManaager.animateLoadViewFade ? 1.0 : 0.0)
                .animation(.easeOut(duration: 1.0), value: launchScreenManaager.animateLoadViewFade)
            
            VStack {
                
                Spacer()
                
                ProgressView("Loading...*")
                    .tint(colorScheme == .dark ? .accentColor : .white)
                    .foregroundColor(colorScheme == .dark ? .accentColor : .white)
                    .scaleEffect(sizeClass == .compact ? 1.0 : 3.0)
                    .opacity(launchScreenManaager.loadingFile ? 1.0 : 0.0)
                    .padding(.bottom, sizeClass == .compact ? 30.0 : 50)

                //Spacer()
                
                
                /*Text("This page will have prettier artwork than this. Promise!")
                    .foregroundColor(colorScheme == .dark ? .accentColor : .white)
                    .font(sizeClass == .compact ? .body : .subheadline)
                    .opacity(launchScreenManaager.loadingFile ? 1.0 : 0.0)*/
                
                
            }
            
        }
        
    }
}




struct SpacecraftLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        SpacecraftLoadingView()
    }
}
