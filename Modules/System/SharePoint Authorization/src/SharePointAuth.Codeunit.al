// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Sharepoint;

/// <summary>
/// Provides functionality for creating means for authorizing HTTP requests made to SharePoint REST API.
/// </summary>
codeunit 9142 "SharePoint Auth."
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Creates an authorization mechanism with authentication code.
    /// </summary>
    /// <param name="EntraTenantId">Microsoft Entra tenant ID</param>
    /// <param name="ClientId">The Application (client) ID that the Azure portal - App registrations experience assigned to your app.</param>        
    /// <param name="ClientSecret">The Application (client) secret configured in the "Azure Portal - Certificates &amp; Secrets".</param>    
    /// <param name="Scope">A scope that you want the user to consent to.</param>
    /// <returns>Codeunit instance implementing authorization interface</returns>
    [NonDebuggable]
    procedure CreateAuthorizationCode(EntraTenantId: Text; ClientId: Text; ClientSecret: Text; Scope: Text): Interface "SharePoint Authorization";
    var
        Scopes: List of [Text];
    begin
        Scopes.Add(Scope);
        exit(CreateAuthorizationCode(EntraTenantId, ClientId, ClientSecret, Scopes));
    end;

    /// <summary>
    /// Creates an authorization mechanism with authentication code.
    /// </summary>
    /// <param name="EntraTenantId">Microsoft Entra tenant ID</param>
    /// <param name="ClientId">The Application (client) ID that the Azure portal - App registrations experience assigned to your app.</param>        
    /// <param name="ClientSecret">The Application (client) secret configured in the "Azure Portal - Certificates &amp; Secrets".</param>    
    /// <param name="Scopes">A list of scopes that you want the user to consent to.</param>
    /// <returns>Codeunit instance implementing authorization interface</returns>
    [NonDebuggable]
    procedure CreateAuthorizationCode(EntraTenantId: Text; ClientId: Text; ClientSecret: Text; Scopes: List of [Text]): Interface "SharePoint Authorization";
    var
        SharePointAuthImpl: Codeunit "SharePoint Auth. - Impl.";
    begin
        exit(SharePointAuthImpl.CreateAuthorizationCode(EntraTenantId, ClientId, ClientSecret, Scopes));
    end;
}