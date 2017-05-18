-- Starfall Derma
-- This is for easily creating derma ui in the style of the Starfall Editor
-- Any derma added should not have anything to do with SF.Editor table apart from design elements e.g. colours, icons

-- Starfall Frame
PANEL = {}

PANEL.windows = {}


surface.CreateFont( "SF_Roboto18", {
	font = "roboto", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	size = 18,
	antialias = true,
} )

function PANEL:Init ()

	self:DockPadding(5,5,5,5)
	self.lblTitle:SetFont("SF_Roboto18")
	self.lblTitle:Dock(TOP)

	self:ShowCloseButton( false )
	self:SetDraggable( true )
	self:SetSizable( true )
	self:SetScreenLock( true )
	self:SetDeleteOnClose( false )
	self:MakePopup()
	self:SetVisible( false )

	local buttonClose = vgui.Create( "StarfallButton", self )
	buttonClose:SetText( "Close" )
	buttonClose.DoClick = function()
		self:Close()
	end

	self._PerformLayout = self.PerformLayout
	function self:PerformLayout ( ... )
		self:_PerformLayout( ... )
		buttonClose:SetPos(self:GetWide()-buttonClose:GetWide()-7,5)
	end

end

PANEL.Paint = function ( panel, w, h )
	draw.RoundedBox( 0, 0, 0, w, h, SF.Editor.colors.dark )
end
function PANEL:Open ()
	self:SetVisible( true )
	self:SetKeyBoardInputEnabled( true )
	self:MakePopup()
	self:InvalidateLayout( true )
end
vgui.Register( "StarfallFrame", PANEL, "DFrame" )
-- End Starfall Frame
--------------------------------------------------------------
--------------------------------------------------------------

-- Starfall Button
PANEL = {}
function PANEL:SetAutoSize(enabled)
	self.AutoSize = enabled
end
function PANEL:Init ()
	self:SetText( "" )
	self:SetSize( 22, 22 )
	_PerformLayout = self.PerformLayout
	self.AutoSize = true
	function self:PerformLayout ()
		if not self.AutoSize then
			return _PerformLayout()
		end
		if self:GetText() != "" then
			self:SizeToContentsX()
			self:SetWide( self:GetWide() + 14 )
		end
	end

	
end
function PANEL:SetIcon ( icon )
	self.icon = SF.Editor.icons[ icon ]
end
PANEL.Paint = function ( button, w, h )
	if button.Hovered or button.active then
		draw.RoundedBox( 0, 0, 0, w, h, button.backgroundHoverCol or SF.Editor.colors.med )
	else
		draw.RoundedBox( 0, 0, 0, w, h, button.backgroundCol or SF.Editor.colors.meddark )
	end
	if button.icon then
		surface.SetDrawColor( SF.Editor.colors.medlight )
		surface.SetMaterial( button.icon )
		surface.DrawTexturedRect( 2, 2, w - 4, h - 4 )
	end
end
function PANEL:UpdateColours ( skin )
	return self:SetTextStyleColor( self.labelCol or SF.Editor.colors.light )
end
function PANEL:SetHoverColor ( col )
	self.backgroundHoverCol = col
end
function PANEL:SetColor ( col )
	self.backgroundCol = col
end
function PANEL:SetLabelColor ( col )
	self.labelCol = col
end
function PANEL:DoClick ()

end

vgui.Register( "StarfallButton", PANEL, "DButton" )
-- End Starfall Button

--------------------------------------------------------------
--------------------------------------------------------------

-- Starfall Panel
PANEL = {}
PANEL.Paint = function ( panel, w, h )
	draw.RoundedBox( 0, 0, 0, w, h, SF.Editor.colors.light )
end
vgui.Register( "StarfallPanel", PANEL, "DPanel" )
-- End Starfall Panel

--------------------------------------------------------------
--------------------------------------------------------------

-- File Tree
local invalid_filename_chars = {
	["*"] = "",
	["?"] = "",
	[">"] = "",
	["<"] = "",
	["|"] = "",
	["\\"] = "",
	['"'] = "",
}

PANEL = {}

function PANEL:Init ()

end
function PANEL:setup ( folder )
	self.folder = folder
	self.Root = self.RootNode:AddFolder( folder, folder, "DATA", true )
	self.Root:SetExpanded( true )
end
function PANEL:reloadTree ()
	self.Root:Remove()
	self:setup( self.folder )
end
function PANEL:DoRightClick ( node )
	self:openMenu( node )
end
function PANEL:openMenu ( node )
	local menu
	if node:GetFileName() then
		menu = "file"
	elseif node:GetFolder() then
		menu = "folder"
	end
	self.menu = vgui.Create( "DMenu", self:GetParent() )
	if menu == "file" then
		self.menu:AddOption( "Open", function ()
				SF.Editor.openFile( node:GetFileName() )
			end )
		self.menu:AddSpacer()
		self.menu:AddOption( "Rename", function ()
				Derma_StringRequestNoBlur(
					"Rename file",
					"",
					string.StripExtension( node:GetText() ),
					function ( text )
						if text == "" then return end
						text = string.gsub( text, ".", invalid_filename_chars )
						local oldFile = node:GetFileName()
						local saveFile = string.GetPathFromFilename( oldFile ) .. "/" .. text ..".txt"
						local contents = file.Read( oldFile )
						file.Delete( node:GetFileName() )
						file.Write( saveFile, contents )
						SF.AddNotify( LocalPlayer(), "File renamed as " .. saveFile .. ".", "GENERIC", 7, "DRIP3" )
						self:reloadTree()
					end
				)
			end )
		self.menu:AddSpacer()
		self.menu:AddOption( "Delete", function ()
				Derma_Query(
					"Are you sure you want to delete this file?",
					"Delete file",
					"Delete",
					function ()
						file.Delete( node:GetFileName() )
						SF.AddNotify( LocalPlayer(), "File deleted: " .. node:GetFileName(), "GENERIC", 7, "DRIP3" )
						self:reloadTree()
					end,
					"Cancel"
				)
			end )
	elseif menu == "folder" then
		self.menu:AddOption( "New file", function ()
				Derma_StringRequestNoBlur(
					"New file",
					"",
					"",
					function ( text )
						if text == "" then return end
						text = string.gsub( text, ".", invalid_filename_chars )
						local saveFile = node:GetFolder().."/"..text..".txt"
						file.Write( saveFile, "" )
						SF.AddNotify( LocalPlayer(), "New file: " .. saveFile, "GENERIC", 7, "DRIP3" )
						self:reloadTree()
					end
				)
			end )
		self.menu:AddSpacer()
		self.menu:AddOption( "New folder", function ()
				Derma_StringRequestNoBlur(
					"New folder",
					"",
					"",
					function ( text )
						if text == "" then return end
						text = string.gsub( text, ".", invalid_filename_chars )
						local saveFile = node:GetFolder().."/"..text
						file.CreateDir( saveFile )
						SF.AddNotify( LocalPlayer(), "New folder: " .. saveFile, "GENERIC", 7, "DRIP3" )
						self:reloadTree()
					end
				)
			end )
		self.menu:AddSpacer()
		self.menu:AddOption( "Delete", function ()
				Derma_Query(
					"Are you sure you want to delete this folder?",
					"Delete folder",
					"Delete",
					function ()
						-- Recursive delete
						local folders = {}
						folders[ #folders + 1 ] = node:GetFolder()
						while #folders > 0 do
							local folder = folders[ #folders ]
							local files, directories = file.Find( folder.."/*", "DATA" )
							for I=1, #files do
								file.Delete( folder .. "/" .. files[I] )
							end
							if #directories == 0 then
								file.Delete( folder )
								folders[ #folders ] = nil
							else
								for I=1, #directories do
									folders[ #folders + 1 ] = folder .. "/" .. directories[ I ]
								end
							end
						end
						SF.AddNotify( LocalPlayer(), "Folder deleted: " .. node:GetFolder(), "GENERIC", 7, "DRIP3" )
						self:reloadTree()
					end,
					"Cancel"
				)
			end )
	end
	self.menu:Open()
end

derma.DefineControl( "StarfallFileTree", "", PANEL, "DTree" )
-- End File Tree

--------------------------------------------------------------
--------------------------------------------------------------

-- File Browser
PANEL = {}

function PANEL:Init ()

	self:Dock( FILL )
	self:DockMargin( 0, 5, 0, 0 )
	self.Paint = function () end

	local tree = vgui.Create( "StarfallFileTree", self )
	tree:Dock( FILL )

	self.tree = tree

	local searchBox = vgui.Create( "DTextEntry", self )
	searchBox:Dock( TOP )
	searchBox:SetValue( "Search..." )

	searchBox._OnGetFocus = searchBox.OnGetFocus
	function searchBox:OnGetFocus ()
		if self:GetValue() == "Search..." then
			self:SetValue( "" )
		end
		searchBox:_OnGetFocus()
	end

	searchBox._OnLoseFocus = searchBox.OnLoseFocus
	function searchBox:OnLoseFocus ()
		if self:GetValue() == "" then
			self:SetText( "Search..." )
		end
		searchBox:_OnLoseFocus()
	end

	function searchBox:OnChange ()

		if self:GetValue() == "" then
			tree:reloadTree()
			return
		end

		tree.Root.ChildNodes:Clear()
		local function containsFile ( dir, search )
			local files, folders = file.Find( dir .. "/*", "DATA" )
			for k, file in pairs( files ) do
				if string.find( string.lower( file ), string.lower( search ) ) then return true end
			end
			for k, folder in pairs( folders ) do
				if containsFile( dir .. "/" .. folder, search ) then return true end
			end
			return false
		end
		local function addFiles ( search, dir, node )
			local allFiles, allFolders = file.Find( dir .. "/*", "DATA" )
			for k, v in pairs( allFolders ) do
				if containsFile( dir .. "/" .. v, search ) then
					local newNode = node:AddNode( v )
					newNode:SetExpanded( true )
					addFiles( search, dir .. "/" .. v, newNode )
				end
			end
			for k, v in pairs( allFiles ) do
				if string.find( string.lower( v ), string.lower( search ) ) then
					local fnode = node:AddNode( v, "icon16/page_white.png" )
					fnode:SetFileName( dir.."/"..v )
				end
			end
		end
		addFiles( self:GetValue():PatternSafe(), "starfall", tree.Root )
		tree.Root:SetExpanded( true )
	end
	self.searchBox = searchBox

	self.Update = vgui.Create("DButton", self)
	self.Update:SetTall(20)
	self.Update:Dock(BOTTOM)
	self.Update:DockMargin(0, 0, 0, 0)
	self.Update:SetText("Update")
	self.Update.DoClick = function(button)
		tree:reloadTree()
		searchBox:SetValue( "Search..." )
	end
end
function PANEL:getComponents ()
	return self.searchBox, self.tree
end

derma.DefineControl( "StarfallFileBrowser", "", PANEL, "DPanel" )
-- End File Browser
