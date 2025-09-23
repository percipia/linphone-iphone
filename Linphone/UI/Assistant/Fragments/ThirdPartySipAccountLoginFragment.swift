/*
 * Copyright (c) 2010-2023 Belledonne Communications SARL.
 *
 * This file is part of linphone-iphone
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import SwiftUI

struct ThirdPartySipAccountLoginFragment: View {
	
	@ObservedObject private var coreContext = CoreContext.shared
	@ObservedObject var accountLoginViewModel: AccountLoginViewModel
	
	@Environment(\.dismiss) var dismiss
	
	@State private var isSecured: Bool = true
	
	@FocusState var isNameFocused: Bool
	@FocusState var isPasswordFocused: Bool
	@FocusState var isDomainFocused: Bool
	@FocusState var isDisplayNameFocused: Bool
	
	var body: some View {
		GeometryReader { geometry in
			if #available(iOS 16.4, *) {
				ScrollView(.vertical) {
					innerScrollView(geometry: geometry)
				}
				.scrollBounceBehavior(.basedOnSize)
			} else {
				ScrollView(.vertical) {
					innerScrollView(geometry: geometry)
				}
			}
		}
		.navigationTitle("")
		.navigationBarHidden(true)
		.edgesIgnoringSafeArea(.bottom)
		.edgesIgnoringSafeArea(.horizontal)
	}
	
	func innerScrollView(geometry: GeometryProxy) -> some View {
		VStack {
			ZStack {
				HStack {
					Image("caret-left")
						.renderingMode(.template)
						.resizable()
						.foregroundStyle(Color.grayMain2c500)
						.frame(width: 25, height: 25)
						.padding(.all, 10)
						.onTapGesture {
							withAnimation {
								accountLoginViewModel.domain = "pbx.percipia.net"
								accountLoginViewModel.transportType = "TLS"
								dismiss()
							}
						}
					Spacer()
				}
				
				Text("assistant_login_third_party_sip_account")
					.default_text_style_800(styleSize: 20)
			}
			.frame(width: geometry.size.width)
			.padding(.top, 10)
			.padding(.bottom, 20)
			
			VStack(alignment: .leading) {
				Text(String(localized: "username")+"*")
					.default_text_style_700(styleSize: 15)
					.padding(.bottom, -5)
				
				TextField("username", text: $accountLoginViewModel.username)
					.default_text_style(styleSize: 15)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.frame(height: 25)
					.padding(.horizontal, 20)
					.padding(.vertical, 15)
					.cornerRadius(60)
					.overlay(
						RoundedRectangle(cornerRadius: 60)
							.inset(by: 0.5)
							.stroke(isNameFocused ? Color.percipiaGreen : Color.gray200, lineWidth: 1)
					)
					.padding(.bottom)
					.focused($isNameFocused)
				
				Text(String(localized: "password")+"*")
					.default_text_style_700(styleSize: 15)
					.padding(.bottom, -5)
				
				ZStack(alignment: .trailing) {
					Group {
						if isSecured {
							SecureField("password", text: $accountLoginViewModel.passwd)
								.default_text_style(styleSize: 15)
								.frame(height: 25)
								.focused($isPasswordFocused)
						} else {
							TextField("password", text: $accountLoginViewModel.passwd)
								.default_text_style(styleSize: 15)
								.disableAutocorrection(true)
								.autocapitalization(.none)
								.frame(height: 25)
								.focused($isPasswordFocused)
						}
					}
					Button(action: {
						isSecured.toggle()
					}, label: {
						Image(self.isSecured ? "eye-slash" : "eye")
							.renderingMode(.template)
							.resizable()
							.foregroundStyle(Color.grayMain2c500)
							.frame(width: 20, height: 20)
					})
				}
				.padding(.horizontal, 20)
				.padding(.vertical, 15)
				.cornerRadius(60)
				.overlay(
					RoundedRectangle(cornerRadius: 60)
						.inset(by: 0.5)
						.stroke(isPasswordFocused ? Color.percipiaGreen : Color.gray200, lineWidth: 1)
				)
				.padding(.bottom)
				
				Text(String(localized: "sip_address_domain")+"*")
					.default_text_style_700(styleSize: 15)
					.padding(.bottom, -5)
				
				TextField("pbx.percipia.net", text: $accountLoginViewModel.domain)
					.default_text_style(styleSize: 15)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.frame(height: 25)
					.padding(.horizontal, 20)
					.padding(.vertical, 15)
					.cornerRadius(60)
					.overlay(
						RoundedRectangle(cornerRadius: 60)
							.inset(by: 0.5)
							.stroke(isDomainFocused ? Color.percipiaGreen : Color.gray200, lineWidth: 1)
					)
					.padding(.bottom)
					.focused($isDomainFocused)
				
				Text(String(localized: "sip_address_display_name"))
					.default_text_style_700(styleSize: 15)
					.padding(.bottom, -5)
				
				TextField("sip_address_display_name", text: $accountLoginViewModel.displayName)
					.default_text_style(styleSize: 15)
					.disableAutocorrection(true)
					.autocapitalization(.none)
					.frame(height: 25)
					.padding(.horizontal, 20)
					.padding(.vertical, 15)
					.cornerRadius(60)
					.overlay(
						RoundedRectangle(cornerRadius: 60)
							.inset(by: 0.5)
							.stroke(isDisplayNameFocused ? Color.percipiaGreen : Color.gray200, lineWidth: 1)
					)
					.padding(.bottom)
					.focused($isDisplayNameFocused)
				
				Text(String(localized: "assistant_sip_account_transport_protocol"))
					.default_text_style_700(styleSize: 15)
					.padding(.bottom, -5)
				
				Menu {
					Button("TLS") {accountLoginViewModel.transportType = "TLS"}
					Button("TCP") {accountLoginViewModel.transportType = "TCP"}
					Button("UDP") {accountLoginViewModel.transportType = "UDP"}
				} label: {
					Text(accountLoginViewModel.transportType)
						.default_text_style(styleSize: 15)
						.frame(maxWidth: .infinity, alignment: .leading)
					Image("caret-down")
						.renderingMode(.template)
						.resizable()
						.foregroundStyle(Color.grayMain2c500)
						.frame(width: 20, height: 20)
				}
				.frame(height: 25)
				.padding(.horizontal, 20)
				.padding(.vertical, 15)
				.cornerRadius(60)
				.overlay(
					RoundedRectangle(cornerRadius: 60)
						.inset(by: 0.5)
						.stroke(Color.gray200, lineWidth: 1)
				)
				.padding(.bottom)
			}
			.frame(maxWidth: SharedMainViewModel.shared.maxWidth)
			.padding(.horizontal, 20)
			
			Spacer()
			
			Button(action: {
				self.accountLoginViewModel.login()
			}, label: {
				Text("assistant_account_login")
					.default_text_style_white_600(styleSize: 20)
					.frame(height: 35)
					.frame(maxWidth: .infinity)
			})
			.padding(.horizontal, 20)
			.padding(.vertical, 10)
			.background(
				(accountLoginViewModel.username.isEmpty || accountLoginViewModel.passwd.isEmpty || accountLoginViewModel.domain.isEmpty)
				? Color.percipiaGreen
				: Color.percipiaGreen)
			.cornerRadius(60)
			.disabled(accountLoginViewModel.username.isEmpty || accountLoginViewModel.passwd.isEmpty || accountLoginViewModel.domain.isEmpty)
			.frame(maxWidth: SharedMainViewModel.shared.maxWidth)
			.padding(.horizontal)
			.padding(.bottom)
			
			Image("mountain2")
				.resizable()
				.scaledToFill()
				.frame(width: geometry.size.width, height: 60)
				.clipped()
		}
		.frame(minHeight: geometry.size.height)
	}
}

#Preview {
	ThirdPartySipAccountLoginFragment(accountLoginViewModel: AccountLoginViewModel())
}
