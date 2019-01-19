local aName, Scrapper = ...;
_G['Scrapper'] = Scrapper;

function Scrapper:Scrap()
	local _, _, classId = UnitClass('player');
	local spec = GetSpecialization();

	local db = ScrapperDb;
	if not db then
		db = {};
		ScrapperDb = db;
	end
	local spells = {};

	for talentRow = 1, 7 do
		for talentCol = 1, 3 do
			local _, name, _, sel, _, id = GetTalentInfo(talentRow, talentCol, 1);
			if id and name then
				spells[id] = self:ParseSpell(id, true);
			end
		end
	end

	local _, _, offset, numSpells = GetSpellTabInfo(2);

	local booktype = 'spell';

	for index = offset + 1, numSpells + offset do
		local id = select(2, GetSpellBookItemInfo(index, booktype));
		local name = GetSpellInfo(id);
		if id and name then
			spells[id] = self:ParseSpell(id, false);
		end
	end

	if not db[classId] then
		db[classId] = {};
	end

	if not db[classId][spec] then
		db[classId][spec] = {};
	end

	db[classId][spec] = spells;
end

function Scrapper:ParseSpell(id, isTalent)
	local name, rank, icon, castTime, minRange, maxRange, spellId = GetSpellInfo(id);
	local isPassive = IsPassiveSpell(id);
	local cooldown = 0;
	local costs = {};

	if not isPassive then
		local cd = GetSpellBaseCooldown(id);
		cooldown = cd and cd / 1000 or 0;
		costs = GetSpellPowerCost(id);
	end

	if not castTime then
		castTime = 0;
	end

	if not costs then
		costs = {};
	end

	return {
		id        = id,
		name      = name,
		castTime  = castTime / 1000,
		minRange  = minRange,
		maxRange  = maxRange,
		isPassive = isPassive,
		isTalent  = isTalent,
		cooldown  = cooldown,
		costs     = costs
	};
end

function Scrapper:ParseCosts(costs)
	local out = '';

	if not costs then
		return '';
	end

	for i, cost in pairs(costs) do
		if out ~= '' then
			out = out .. ';';
		end

		out = out .. cost.name .. ':' .. cost.minCost;
	end

	return out;
end

function Scrapper:Generate()
	local db = ScrapperDb;
	local _, _, classId = UnitClass('player');
	local spec = GetSpecialization();

	local output = string.format(
		'%s,%s,%s,%s,%s,%s,%s,%s,%s',
		'id',
		'name',
		'castTime',
		'minRange',
		'maxRange',
		'isPassive',
		'isTalent',
		'cooldown',
		'costs'
	) .. '\n';

	local spells = db[classId][spec];
	for i, spell in pairs(spells) do
		output = output .. string.format(
			'%u,%s,%f,%u,%u,%u,%u,%f,%s',
			spell.id,
			spell.name,
			spell.castTime,
			spell.minRange,
			spell.maxRange,
			spell.isPassive and 1 or 0,
			spell.isTalent and 1 or 0,
			spell.cooldown,
			self:ParseCosts(spell.costs)
		) .. '\n';
	end

	return output;
end

function Scrapper:Show()
	self:Scrap();
	local StdUi = LibStub('StdUi');

	if self.frame then
		self.editBox:SetText(self:Generate());
		self.frame:Show();
		return ;
	end

	local f = StdUi:Window(UIParent, 'MaxDps Scrapper', 500, 600);
	f:SetPoint('CENTER');

	local editBox = StdUi:MultiLineBox(f, 480, 550);
	editBox:SetText(self:Generate());
	StdUi:GlueTop(editBox.panel, f, 0, -30, 'CENTER');

	f:Show();

	self.frame = f;
	self.editBox = editBox;
end