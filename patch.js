function patch(obj,diff){
 var merge = function(o,k,v){
            var curr = o;
            var arr = k.split(".")
            var len =  arr.length
            var key = ""
            for (var i = 1; i < len-1; i++) {
                if (isNaN(Number(arr[i]))){
                    key = arr[i]
                }else{
                    key = (Number(arr[i]) -1)
                }
                curr = curr[key]
            }
            curr[arr[len-1]] = (v == "nil"?null:v)
        }
        for (var i =0 ;i<diff.length;i++){
            for(var key in diff){
                merge(obj,key,diff[key])
            }
        }
        return obj
}

