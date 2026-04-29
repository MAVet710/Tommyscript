Leaderboard = {}
function Leaderboard.Get(limit)
 local order = ({xp='xp DESC',completed='completed_contracts DESC',crypto='total_crypto_earned DESC',success_rate='(completed_contracts/IF((completed_contracts+failed_contracts)=0,1,(completed_contracts+failed_contracts))) DESC'})[Config.LeaderboardSort] or 'xp DESC'
 return DB.query('SELECT profile_name, level, xp, completed_contracts, failed_contracts, total_crypto_earned, last_active FROM tommy_boosting_players ORDER BY '..order..' LIMIT ?', {limit or 50})
end
