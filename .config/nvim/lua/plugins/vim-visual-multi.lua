return {
	{
		"mg979/vim-visual-multi",
		branch = "master",
		init = function()
			-- Değişkenleri doğrudan tablonun (dictionary) içine yerleştiriyoruz
			vim.g.VM_maps = {
				["Find Under"] = "<C-d>", -- Normal modda kelimeyi bul/seç
				["Find Subword Under"] = "<C-d>", -- Görsel modda seçili metni bul/seç
			}
		end,
	},
}
