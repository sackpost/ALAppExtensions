// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration;

using System.Environment;
using System.Environment.Configuration;
using System.Reflection;

permissionset 2715 "Page Summary Provider - Read"
{
    Access = Internal;
    Assignable = false;

    IncludedPermissionSets = "Page Summary Provider - Obj.";

    Permissions = tabledata Company = r,
                  tabledata "Page Data Personalization" = R, // DotNet NavPageSummaryALFunctions requires this
                  tabledata "Page Metadata" = r,
                  tabledata "Tenant Media Thumbnails" = r,
                  tabledata "Tenant Media Set" = r,
                  tabledata "Media Resources" = r,
                  tabledata Media = r; // Page Summary Provider Settings Wizard requires this
}
