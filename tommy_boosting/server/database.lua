DB = {}
function DB.query(q,p) return MySQL.query.await(q,p or {}) end
function DB.single(q,p) return MySQL.single.await(q,p or {}) end
function DB.update(q,p) return MySQL.update.await(q,p or {}) end
