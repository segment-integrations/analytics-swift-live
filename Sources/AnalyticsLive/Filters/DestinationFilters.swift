//
//  DestinationFilters.swift
//  AnalyticsLive
//
//  Created by Brandon Sneed on 3/21/25.
//

import Foundation
import Segment
import Substrata

public class DestinationFilters: Plugin {
    public var type: PluginType = .utility
    public weak var analytics: Analytics? = nil
    internal var engine: JSEngine?
    internal var plugins = [DestinationFilter]()
    
    internal var tsubScript = #"""
        var dest_filters=function(e){var r={};function t(n){if(r[n])return r[n].exports;var o=r[n]={i:n,l:!1,exports:{}};return e[n].call(o.exports,o,o.exports,t),o.l=!0,o.exports}return t.m=e,t.c=r,t.d=function(e,r,n){t.o(e,r)||Object.defineProperty(e,r,{enumerable:!0,get:n})},t.r=function(e){"undefined"!=typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(e,Symbol.toStringTag,{value:"Module"}),Object.defineProperty(e,"__esModule",{value:!0})},t.t=function(e,r){if(1&r&&(e=t(e)),8&r)return e;if(4&r&&"object"==typeof e&&e&&e.__esModule)return e;var n=Object.create(null);if(t.r(n),Object.defineProperty(n,"default",{enumerable:!0,value:e}),2&r&&"string"!=typeof e)for(var o in e)t.d(n,o,function(r){return e[r]}.bind(null,o));return n},t.n=function(e){var r=e&&e.__esModule?function(){return e.default}:function(){return e};return t.d(r,"a",r),r},t.o=function(e,r){return Object.prototype.hasOwnProperty.call(e,r)},t.p="",t(t.s=5)}([function(e,r,t){e.exports=function(e,r,t,n,o){for(r=r.split?r.split("."):r,n=0;n<r.length;n++)e=e?e[r[n]]:o;return e===o?t:e}},function(e,r,t){"use strict";var n,o=t(19);e.exports=((n=new o.uint16(1))[0]=4660,52===new o.uint8(n.buffer)[0])},function(e,r,t){"use strict";var n=t(18),o=new Float64Array(1),i=new Uint32Array(o.buffer);e.exports=function(e){return o[0]=e,i[n]}},function(e,r,t){"use strict";var n=t(21),o=new Float64Array(1),i=new Uint32Array(o.buffer),u=n.HIGH,a=n.LOW;e.exports=function(e){return o[0]=e,[i[u],i[a]]}},function(e,r,t){"use strict";var n=t(22),o=new Float64Array(1),i=new Uint32Array(o.buffer),u=n.HIGH,a=n.LOW;e.exports=function(e,r){return i[u]=e,i[a]=r,o[0]}},function(e,r,t){"use strict";Object.defineProperty(r,"__esModule",{value:!0});const n=t(6);r.default={evaluateDestinationFilters:function(e,r){for(var t=r,o=e.matchers,i=e.transformers,u=0;u<o.length;u++)if(n.matches(t,o[u])&&null===(t=n.transform(t,i[u])))return null;return t}}},function(e,r,t){"use strict";Object.defineProperty(r,"__esModule",{value:!0}),r.Store=r.matches=r.transform=void 0;var n=t(7);Object.defineProperty(r,"transform",{enumerable:!0,get:function(){return n.default}});var o=t(25);Object.defineProperty(r,"matches",{enumerable:!0,get:function(){return o.default}});var i=t(26);Object.defineProperty(r,"Store",{enumerable:!0,get:function(){return i.default}})},function(e,r,t){"use strict";Object.defineProperty(r,"__esModule",{value:!0});var n=t(8),o=t(0),i=t(9),u=t(23),a=t(24);function s(e,r){for(var t in r.drop)if(r.drop.hasOwnProperty(t)){var n=""===t?e:o(e,t);if("object"==typeof n&&null!==n)for(var i=0,u=r.drop[t];i<u.length;i++){delete n[u[i]]}}}function c(e,r){for(var t in r.allow)if(r.allow.hasOwnProperty(t)){var n=""===t?e:o(e,t);if("object"==typeof n&&null!==n)for(var i in n)n.hasOwnProperty(i)&&-1===r.allow[t].indexOf(i)&&delete n[i]}}function f(e,r){var t=JSON.parse(JSON.stringify(e));for(var n in r.map)if(r.map.hasOwnProperty(n)){var i=r.map[n],s=n.split("."),c=void 0;if(s.length>1?(s.pop(),c=o(t,s.join("."))):c=e,"object"==typeof c){if(i.copy){var f=o(t,i.copy);void 0!==f&&u(e,n,f)}else if(i.move){var l=o(t,i.move);void 0!==l&&u(e,n,l),a.unset(e,i.move)}else i.hasOwnProperty("set")&&u(e,n,i.set);if(i.to_string){var p=o(e,n);if("string"==typeof p||"object"==typeof p&&null!==p)continue;u(e,n,void 0!==p?JSON.stringify(p):"undefined")}}}}function l(e,r){return!(r.sample.percent<=0)&&(r.sample.percent>=1||(r.sample.path?function(e,r){var t=o(e,r.sample.path),u=n(JSON.stringify(t)),a=-64,s=[];p(u.slice(0,8),s);for(var c=0,f=0;f<64&&1!==s[f];f++)c++;if(0!==c){var l=[];p(u.slice(9,16),l),a-=c,s.splice(0,c),l.splice(64-c),s=s.concat(l)}return s[63]=0===s[63]?1:0,i(parseInt(s.join(""),2),a)<r.sample.percent}(e,r):(t=r.sample.percent,Math.random()<=t)));var t}function p(e,r){for(var t=0;t<8;t++)for(var n=e[t],o=128;o>=1;o/=2)n-o>=0?(n-=o,r.push(1)):r.push(0)}r.default=function(e,r){for(var t=e,n=0,o=r;n<o.length;n++){var i=o[n];switch(i.type){case"drop":return null;case"drop_properties":s(t,i.config);break;case"allow_properties":c(t,i.config);break;case"sample_event":if(l(t,i.config))break;return null;case"map_properties":f(t,i.config);break;case"hash_properties":break;default:throw new Error('Transformer of type "'+i.type+'" is unsupported.')}}return t}},function(e,r,t){"use strict";t.r(r);for(var n=[],o=0;o<64;)n[o]=0|4294967296*Math.sin(++o%Math.PI);r.default=function(e){var r,t,i,u=[r=1732584193,t=4023233417,~r,~t],a=[],s=unescape(encodeURI(e))+"",c=s.length;for(e=--c/4+2|15,a[--e]=8*c;~c;)a[c>>2]|=s.charCodeAt(c)<<8*c--;for(o=s=0;o<e;o+=16){for(c=u;s<64;c=[i=c[3],r+((i=c[0]+[r&t|~r&i,i&r|~i&t,r^t^i,t^(r|~i)][c=s>>4]+n[s]+~~a[o|15&[s,5*s+1,3*s+5,7*s][c]])<<(c=[7,12,17,22,5,9,14,20,4,11,16,23,6,10,15,21][4*c+s++%4])|i>>>-c),r,t])r=0|c[1],t=c[2];for(s=4;s;)u[--s]+=c[s]}for(e="";s<32;)e+=(u[s>>3]>>4*(1^s++)&15).toString(16);return e}},function(e,r,t){"use strict";var n=t(10),o=t(11),i=t(12),u=t(17),a=t(20),s=t(3),c=t(4);e.exports=function(e,r){var t,f,l,p;return 0===e||e!=e||e===n||e===o?e:(e=(f=i(e))[0],r+=f[1],(r+=u(e))<-1074?a(0,e):r>1023?e<0?o:n:(r<=-1023?(r+=52,p=2220446049250313e-31):p=1,t=(l=s(e))[0],t&=2148532223,p*c(t|=r+1023<<20,l[1])))}},function(e,r,t){"use strict";e.exports=Number.POSITIVE_INFINITY},function(e,r,t){"use strict";e.exports=Number.NEGATIVE_INFINITY},function(e,r,t){"use strict";var n=t(13).VALUE,o=t(15),i=t(16);e.exports=function(e){return e!=e||o(e)?[e,0]:0!==e&&i(e)<n?[4503599627370496*e,-52]:[e,0]}},function(e,r,t){"use strict";var n=t(14),o={};n(o,"VALUE",22250738585072014e-324),n(o,"DENORMALIZED",5e-324),e.exports=o},function(e,r,t){"use strict";e.exports=function(e,r,t){Object.defineProperty(e,r,{value:t,configurable:!1,writable:!1,enumerable:!0})}},function(e,r,t){"use strict";var n=Number.POSITIVE_INFINITY,o=Number.NEGATIVE_INFINITY;e.exports=function(e){return e===n||e===o}},function(e,r,t){"use strict";e.exports=function(e){return e<0?-e:0===e?0:e}},function(e,r,t){"use strict";var n=t(2);e.exports=function(e){var r=n(e);return(r=(2146435072&r)>>>20)-1023}},function(e,r,t){"use strict";var n;n=!0===t(1)?1:0,e.exports=n},function(e,r,t){"use strict";var n={uint16:Uint16Array,uint8:Uint8Array};e.exports=n},function(e,r,t){"use strict";var n=t(3),o=t(2),i=t(4);e.exports=function(e,r){var t,u;return t=(e=n(e))[0],t&=2147483647,u=o(r),i(t|=u&=2147483648,e[1])}},function(e,r,t){"use strict";var n,o;t(1)?(n=1,o=0):(n=0,o=1),e.exports={HIGH:n,LOW:o}},function(e,r,t){"use strict";var n,o;!0===t(1)?(n=1,o=0):(n=0,o=1),e.exports={HIGH:n,LOW:o}},function(e,r){e.exports=function(e,r,t){r.split&&(r=r.split("."));for(var n,o,i=0,u=r.length,a=e;i<u;)"__proto__"!==(o=r[i++])&&"constructor"!==o&&"prototype"!==o&&(a=a[o]=i===u?t:null!=(n=a[o])?n:0*r[i]!=0||~r[i].indexOf(".")?{}:[])}},function(e,r,t){"use strict";Object.defineProperty(r,"__esModule",{value:!0}),r.unset=void 0;var n=t(0);r.unset=function(e,r){if(n(e,r)){for(var t=r.split("."),o=t.pop();t.length&&"\\"===t[t.length-1].slice(-1);)o=t.pop().slice(0,-1)+"."+o;for(;t.length;)e=e[r=t.shift()];return delete e[o]}return!0}},function(e,r,t){"use strict";Object.defineProperty(r,"__esModule",{value:!0});var n=t(0);function o(e,r){if(!Array.isArray(e))return!0===i(e,r);var t=e[0];switch(t){case"!":return!o(e[1],r);case"or":for(var n=1;n<e.length;n++)if(o(e[n],r))return!0;return!1;case"and":for(n=1;n<e.length;n++)if(!o(e[n],r))return!1;return!0;case"=":case"!=":return function(e,r,t,n){u(e)&&(e=o(e,n));u(r)&&(r=o(r,n));"object"==typeof e&&"object"==typeof r&&(e=JSON.stringify(e),r=JSON.stringify(r));switch(t){case"=":return e===r;case"!=":return e!==r;default:throw new Error("Invalid operator in compareItems: "+t)}}(i(e[1],r),i(e[2],r),t,r);case"<=":case"<":case">":case">=":return function(e,r,t,n){u(e)&&(e=o(e,n));u(r)&&(r=o(r,n));if("number"!=typeof e||"number"!=typeof r)return!1;switch(t){case"<=":return e<=r;case">=":return e>=r;case"<":return e<r;case">":return e>r;default:throw new Error("Invalid operator in compareNumbers: "+t)}}(i(e[1],r),i(e[2],r),t,r);case"contains":return function(e,r){if("string"!=typeof e||"string"!=typeof r)return!1;return-1!==e.indexOf(r)}(i(e[1],r),i(e[2],r));case"match":return function(e,r){if("string"!=typeof e||"string"!=typeof r)return!1;return function(e,r){var t,n;e:for(;e.length>0;){var o,i;if(t=a(e),o=t.star,i=t.chunk,e=t.pattern,o&&""===i)return!0;var u=s(i,r),c=u.t,f=u.ok,l=u.err;if(l)return!1;if(!f||!(0===c.length||e.length>0)){if(o)for(var p=0;p<r.length;p++){if(n=s(i,r.slice(p+1)),c=n.t,f=n.ok,l=n.err,f){if(0===e.length&&c.length>0)continue;r=c;continue e}if(l)return!1}return!1}r=c}return 0===r.length}(r,e)}(i(e[1],r),i(e[2],r));case"lowercase":var c=i(e[1],r);return"string"!=typeof c?null:c.toLowerCase();case"typeof":return typeof i(e[1],r);case"length":return function(e){if(null===e)return 0;if(!Array.isArray(e)&&"string"!=typeof e)return NaN;return e.length}(i(e[1],r));default:throw new Error("FQL IR could not evaluate for token: "+t)}}function i(e,r){return Array.isArray(e)?e:"object"==typeof e?e.value:n(r,e)}function u(e){return!!Array.isArray(e)&&(("lowercase"===e[0]||"length"===e[0]||"typeof"===e[0])&&2===e.length||("contains"===e[0]||"match"===e[0])&&3===e.length)}function a(e){for(var r={star:!1,chunk:"",pattern:""};e.length>0&&"*"===e[0];)e=e.slice(1),r.star=!0;var t,n=!1;e:for(t=0;t<e.length;t++)switch(e[t]){case"\\":t+1<e.length&&t++;break;case"[":n=!0;break;case"]":n=!1;break;case"*":if(!n)break e}return r.chunk=e.slice(0,t),r.pattern=e.slice(t),r}function s(e,r){for(var t,n,o={t:"",ok:!1,err:!1};e.length>0;){if(0===r.length)return o;switch(e[0]){case"[":var i=r[0];r=r.slice(1);var u=!0;(e=e.slice(1)).length>0&&"^"===e[0]&&(u=!1,e=e.slice(1));for(var a=!1,s=0;;){if(e.length>0&&"]"===e[0]&&s>0){e=e.slice(1);break}var f,l="";if(f=(t=c(e)).char,e=t.newChunk,t.err)return o;if(l=f,"-"===e[0]&&(l=(n=c(e.slice(1))).char,e=n.newChunk,n.err))return o;f<=i&&i<=l&&(a=!0),s++}if(a!==u)return o;break;case"?":r=r.slice(1),e=e.slice(1);break;case"\\":if(0===(e=e.slice(1)).length)return o.err=!0,o;default:if(e[0]!==r[0])return o;r=r.slice(1),e=e.slice(1)}}return o.t=r,o.ok=!0,o.err=!1,o}function c(e){var r={char:"",newChunk:"",err:!1};return 0===e.length||"-"===e[0]||"]"===e[0]||"\\"===e[0]&&0===(e=e.slice(1)).length?(r.err=!0,r):(r.char=e[0],r.newChunk=e.slice(1),0===r.newChunk.length&&(r.err=!0),r)}r.default=function(e,r){if(!r)throw new Error("No matcher supplied!");switch(r.type){case"all":return!0;case"fql":return function(e,r){if(!e)return!1;try{e=JSON.parse(e)}catch(r){throw new Error('Failed to JSON.parse FQL intermediate representation "'+e+'": '+r)}var t=o(e,r);if("boolean"!=typeof t)return!1;return t}(r.ir,e);default:throw new Error("Matcher of type "+r.type+" unsupported.")}}},function(e,r,t){"use strict";Object.defineProperty(r,"__esModule",{value:!0});var n=function(){function e(e){this.rules=[],this.rules=e||[]}return e.prototype.getRulesByDestinationName=function(e){for(var r=[],t=0,n=this.rules;t<n.length;t++){var o=n[t];o.destinationName!==e&&void 0!==o.destinationName||r.push(o)}return r},e}();r.default=n}]).default;
    """#
    
    #if DEBUG
    internal var tsubEvaluate = #"""
    function evaluateRules(rules, event) {
        const result = dest_filters.evaluateDestinationFilters(rules, event);
        result.context.filterRan = true;
        return result
    }
    """#
    #else
    internal var tsubEvaluate = #"""
    function evaluateRules(rules, event) {
        const result = dest_filters.evaluateDestinationFilters(rules, event);
        return result
    }
    """#
    #endif
    
    public func update(settings: Settings, type: UpdateType) {
        if engine == nil {
            engine = JSEngine()
            engine?.setLimits(stackSize: 1024 * 1024, heapSize: 1024 * 1024 * 32)
            engine?.evaluate(script: tsubScript, evaluator: "DestinationFilters.tsubScript")
            engine?.evaluate(script: tsubEvaluate, evaluator: "DestinationFilters.tsubEvaluate")
        }
        
        removeExistingFilters()
        
        settings.middlewareSettings?["routingRules"]?
            .arrayValue?
            .compactMap { $0 as? [String: Any] }
            .forEach { rule in
                if let destination = rule["destinationName"] as? String,
                   !destination.isEmpty {
                    createFilter(key: destination, rules: rule)
                }
            }
    }
    
    public func execute<T: RawEvent>(event: T?) -> T? {
        // we operate as a utility and are out of the event stream
        return event
    }
    
    public func shutdown() {
        engine = nil
    }
    
    internal func removeExistingFilters() {
        for plugin in plugins {
            let dest = analytics?.find(key: plugin.key)
            if let filters = dest?.findAll(pluginType: DestinationFilter.self) {
                for filter in filters {
                    dest?.remove(plugin: filter)
                }
            }
        }
    }
    
    internal func createFilter(key: String, rules: [String: Any]) {
        if let dest = analytics?.find(key: key) {
            let filter = DestinationFilter(key: key, engine: engine, rules: rules)
            _ = dest.add(plugin: filter)
            plugins.append(filter)
        }
    }
}

internal class DestinationFilter: Plugin {
    var type: PluginType = .enrichment
    weak var analytics: Segment.Analytics? = nil
    weak var engine: JSEngine?
    let key: String
    let rules: [String: Any]
    
    init(key: String, engine: JSEngine?, rules: [String: Any]) {
        self.engine = engine
        self.key = key
        self.rules = rules
    }
    
    func execute<T: RawEvent>(event: T?) -> T? {
        guard let event else { return event }
        guard let engine else { return event }
        
        var result: T? = event
        if let eval = engine.value(for: "evaluateRules") as? JSFunction {
            let jsRules = rules.toJSConvertible()
            guard let jsEvent = toDictionary(event)?.toJSConvertible() else { return result }
            let modified = eval.call(args: [jsRules, jsEvent])?.typed(as: Dictionary.self)
            
            if let newEvent = modified {
                result = T(fromDictionary: newEvent)
            } else {
                result = nil
            }
        }
        return result
    }
}
