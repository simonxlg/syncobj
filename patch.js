function patch(obj,diff){
    var merge = function(o,k,v){
            var curr = o;
            var arr = k.split(".")
            var len =  arr.length
            for (var i = 1; i < len-2; i++) {
                curr = obj[arr[i]]
            }
            var key = arr[len-1]
            curr[key] = (v == "nil"?null:v)
        }
    for(var key in diff){
        merge(obj,key,diff[key])
    }
    return obj
}