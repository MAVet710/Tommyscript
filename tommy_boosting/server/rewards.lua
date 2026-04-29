Rewards = {}

function Rewards.Give(src, profile, contract)
    Bridge.AddMoney(src, 'cash', contract.cash_reward)
    DB.update('UPDATE tommy_boosting_players SET crypto = crypto + ?, xp = xp + ?, completed_contracts = completed_contracts + 1, total_cash_earned = total_cash_earned + ?, total_crypto_earned = total_crypto_earned + ?, total_xp_earned = total_xp_earned + ? WHERE identifier = ?', {
        contract.crypto_reward, contract.xp_reward, contract.cash_reward, contract.crypto_reward, contract.xp_reward, profile.identifier
    })

    local updated = DB.single('SELECT * FROM tommy_boosting_players WHERE identifier=?', { profile.identifier })
    if not updated then return end
    local newLevel = Utils.CalcLevel(updated.xp)
    if newLevel ~= updated.level then
        DB.update('UPDATE tommy_boosting_players SET level=? WHERE identifier=?', { newLevel, profile.identifier })
        Bridge.Notify(src, ('Tommy Boosting level up! Level %d'):format(newLevel), 'success')
    end
end
