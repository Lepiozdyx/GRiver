import SwiftUI

struct ShopView: View {
    @EnvironmentObject var coordinator: AppCoordinator
    
    var body: some View {
        ZStack {
            Image(.menuBg).resizable().ignoresSafeArea()
            
            topBarControl
            
            shopContent
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var topBarControl: some View {
        VStack {
            HStack(alignment: .top, spacing: 16) {
                Button {
                    coordinator.navigateToMainMenu()
                } label: {
                    Image(.squareButton)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(.homeIcon)
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                }
                
                Spacer()
                
                Image(.frame1)
                    .resizable()
                    .frame(width: 200, height: 40)
                    .overlay {
                        Text("Shop")
                            .laborFont(20)
                    }
                
                Spacer()
            }
            Spacer()
        }
        .padding()
    }
    
    private var shopContent: some View {
        ZStack {
            Image(.frame1)
                .resizable()
                .frame(width: 650, height: 250)
            
            HStack {
                Image(.rectangleButton)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 150)
                    .overlay {
                        Text("Maps")
                            .laborFont(20)
                    }
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button {
                        // previous asset
                    } label: {
                        Image(.squareButton)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 60)
                            .overlay {
                                Image(systemName: "arrowshape.left.fill")
                                    .resizable()
                                    .foregroundStyle(.white)
                                    .frame(width: 30, height: 15)
                            }
                    }
                    
                    Image(.squareButton)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200)
                        .overlay {
                            // Dynamic content
                            Image(.map1)
                                .resizable()
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .padding(22)
                                .offset(x: 2, y: -3)
                        }
                        .overlay(alignment: .bottom) {
                            Button {
                                // use asset
                            } label: {
                                Image(.rectangleButton)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 120)
                                    .overlay {
                                        HStack(spacing: 2) {
                                            Text("use")
                                                .laborFont(12)
                                        }
                                    }
                            }
                        }
                    
                    Button {
                        // next asset
                    } label: {
                        Image(.squareButton)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 60)
                            .overlay {
                                Image(systemName: "arrowshape.right.fill")
                                    .resizable()
                                    .foregroundStyle(.white)
                                    .frame(width: 30, height: 15)
                            }
                    }
                }
            }
            .frame(width: 600, height: 200)
        }
    }
}

#Preview {
    ShopView()
        .environmentObject(AppCoordinator())
}
