					--caliber reading
					if self.PresetName == "Makarov PM Ammo Can" then
						self.caliber = "6x30mm"
						self.boxmass = 0.01 * 8
					elseif self.PresetName == "M1911A1 Ammo Can" then
						self.caliber = "6x50mm"
						self.boxmass = 0.015 * 7
					elseif self.PresetName == "AKM Ammo Can" then
						self.caliber = "6x80mm"
						self.boxmass = 0.03 * 30
					elseif self.PresetName == "CZ 550 Ammo Can" then
						self.caliber = "12x120mm"
						self.boxmass = 0.035 * 5
					elseif self.PresetName == "G17 Ammo Can" then
						self.caliber = "12x25mm"
						self.boxmass = 0.012 * 17
					end