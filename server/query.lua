function CheckPlayerJail(charId)
    return MySQL.Sync.fetchAll('SELECT * FROM jail WHERE charId = ?', { charId })
end

function SetPlayerToJail(charId, jailTime)
    return MySQL.Sync.execute('INSERT INTO jail (charId, jail_time) VALUES (?, ?)', { 
        charId,
        jailTime
    })
end

function UpdateJailPlayer(charId, jailTime)
    return MySQL.Sync.execute("UPDATE jail SET jail_time = ? WHERE charId = ?", {
        jailTime,
        charId        
    })
end

function RemoveJailPlayer(charId)
    return MySQL.Sync.execute('DELETE FROM jail WHERE charId = ? ', { charId })
end