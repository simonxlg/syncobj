synctable 解决的问题是数据同步存在的痛点
典型的场景：
	如果有一个 table userinfo = {user_id = 10001, nickname = "simon", gold = 8888}
	这个 userinfo 在用户登陆的时候是由 DB代理去（机器1） 数据库中加载后发给 逻辑处理模块（机器2）
	那么就存在 DB代理和逻辑处理模块数据同步问题，譬如用户的金币 gold 值改变了。
	同步这个数据一般有两种做法：	
		1.在 DB代理中写一个接口 update_gold 来处理 gold 值的变化，这种办法会随着接口越来越多而导致代码很难看和一堆 update_xxx 接口。
		2.在 DB代理中写一个接口 updata_userinfo 来全量更新 userinfo ，这种办法在 userinfo 很多字段的情况下浪费过多的流量和执行消耗。
	synctable 的目的就是为了解决上述问题而设计的。
	synctable 可以跟踪逻辑处理模 userinfo （随便一个普通的 table, 调用 synctable.create(userinfo) ）的属性变化，并且生成变化记录 diff（调用 synctable.diff）。
	在后续DB代理中的 synctable.patch(DB代理中的 userinfo， 逻辑处理模块变化记录 diff) 就可以把 userinfo 同步到 DB代理。
	可以做到用最小的代价来解决这个痛点。

限制：
	由于 synctable 是利用了 table 的 __newindex 来记录变化，所以在使用通过 synctable.create(userinfo) 生产出来的副本时候有下列限制：
		1.数组的元素增删需要用 synctable.remove 替换 table.remove、 synctable.insert table.insert
		2.如果动态加了新字段或者 数组 insert 元素，以及 数组 remove 元素。都要及时同步，否则会导致异常。
		3.不要对 synctable 生成的副本频繁加字段删字段，而是改变字段的值！！！
