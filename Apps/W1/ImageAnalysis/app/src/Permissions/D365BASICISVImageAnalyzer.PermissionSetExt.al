namespace System.Security.AccessControl;

using Microsoft.Utility.ImageAnalysis;
using System.Security.AccessControl;

permissionsetextension 29582 "D365 BASIC ISVImage Analyzer" extends "D365 BASIC ISV"
{
    Permissions = tabledata "MS - Image Analyzer Tags" = RIMD,
                  tabledata "MS - Img. Analyzer Blacklist" = RIMD;
}
