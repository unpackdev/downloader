// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.15;

/* Resources on YUL programming */

// LINK https://medium.com/@jtriley15/yul-vs-solidity-contract-comparison-2b6d9e9dc833
// LINK https://github.com/FuelLabs/yulp
// LINK https://hackernoon.com/programming-tutorial-getting-started-with-yul
// LINK https://github.com/FuelLabs/yulp/tree/master/examples
// LINK https://docs.soliditylang.org/en/v0.8.9/yul.html#specification-of-yul
// LINK https://mirror.xyz/0xB38709B8198d147cc9Ff9C133838a044d78B064B/Hh69VJWM5eiFYFINxYWrIYWcRRtPm8tw3VFjpdpx6T8


contract ASM { // NOTE Includes ERC20 interface routing

 // SECTION Constructor
    constructor() {
        assembly {
            // ANCHOR Set initial totalSupply
            let tsupply := 1000000000000000000000000000 // 1000000000 * (10 ** 18)
            sstore(0, caller())
            sstore(1, tsupply)
        }
    }
    // !SECTION

    // SECTION Fallback
    // NOTE Fallback will be called by default and will then route to assembly
    fallback() external {
        assembly {

            // NOTE Non payable
            require(iszero(callvalue()))

            // SECTION Token properties
            // ANCHOR Define the token name
            function name() -> n {
                n := "Assembled Token"
            }

            // ANCHOR Define the token symbol
            function symbol() -> s {
                s := "ASTOK"
            }
            
            // ANCHOR Set Decimals
            function decimals() -> d { 
                d := 18 
            }

            // NOTE totalSupply is defined in the constructor

            // !SECTION

            // SECTION Primitives

            // ANCHOR require asm definition
             function require(condition) {
                if iszero(condition) { revert(0, 0) }
            }

            // ANCHOR Loading of the first slot of calldata (the call parameter) and
            //        gives first four bytes of the abovementioned slot
            function selector() -> s {
                s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)
            }

            // ANCHOR Returning an Uint by storing it in memory and calling it out
            function returnUint(v) {
                mstore(0, v)
                return(0, 0x20)
            }
            // !SECTION

            // SECTION ERC20 Conformity

            // ANCHOR Mint
            function mint(account, amount) {
                require(calledByOwner())
                mintTokens(amount)
                addToBalance(account, amount)
                emitTransfer(0, account, amount)
            }

            // ANCHOR Burn
            function burn(account, amount) {
                require(calledByOwner())
                burnTokens(amount)
                deductFromBalance(account, amount)
                emitTransfer(account, 0, amount)
            }

            // ANCHOR transfer
            function transfer(to, amount) {
                executeTransfer(caller(), to, amount)
            }

            // ANCHOR Approve
            function approve(spender, amount) {
                revertIfZeroAddress(spender)
                setAllowance(caller(), spender, amount)
                emitApproval(caller(), spender, amount)
            }

            // ANCHOR transferFrom
            function transferFrom(from, to, amount) {
                require(gt(allowance(from, caller()), amount))
                decreaseAllowanceBy(from, caller(), amount)
                executeTransfer(from, to, amount)
            }

            // ANCHOR Effective transfer
            function executeTransfer(from, to, amount) {
                revertIfZeroAddress(to)
                deductFromBalance(from, amount)
                addToBalance(to, amount)
                emitTransfer(from, to, amount)
            }
            // !SECTION

            // SECTION calldata decoding as needed

            function decodeAsAddress(offset) -> v {
                v := decodeAsUint(offset)
                if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
            }
            function decodeAsUint(offset) -> v {
                let pos := add(4, mul(offset, 0x20))
                if lt(calldatasize(), add(pos, 0x20)) {
                    revert(0, 0)
                }
                v := calldataload(pos)
            }

            // !SECTION


            // SECTION Events emission 
            function emitTransfer(from, to, amount) {
                let signatureHash := 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
                emitEvent(signatureHash, from, to, amount)
            }
            function emitApproval(from, spender, amount) {
                let signatureHash := 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925
                emitEvent(signatureHash, from, spender, amount)
            }
            function emitEvent(signatureHash, indexed1, indexed2, nonIndexed) {
                mstore(0, nonIndexed)
                log3(0, 0x20, signatureHash, indexed1, indexed2)
            }
            // !SECTION

            // SECTION Storage layout definition
            function ownerPos() -> p { p := 0 }
            function totalSupplyPos() -> p { p := 1 }
            function accountToStorageOffset(account) -> offset {
                offset := add(0x1000, account)
            }
            function allowanceStorageOffset(account, spender) -> offset {
                offset := accountToStorageOffset(account)
                mstore(0, offset)
                mstore(0x20, spender)
                offset := keccak256(0, 0x40)
            }
            // !SECTION

            // SECTION Mathematics
            function safeAdd(x, y)  -> z {
                
                z := add(x, y)
                require(or(eq(z,x), gt(z,x)))
            }

            function safeSub(x, y)  -> z {
                
                z := sub(x, y)

                require(or(eq(z,x), lt(z, x)))
            }

            function safeMul(x, y)  -> z {
                
                if gt(y, 0) {
                    z := mul(x, y)
                }
                require(eq(div(z,y), x))
            }

            function safeDiv(x, y)  -> z {
                require(gt(y,0))
                
                z := div(x, y)
            }
            // !SECTION

            // SECTION Storage read access
            function owner() -> o {
                o := sload(ownerPos())
            }
            function totalSupply() -> supply {
                supply := sload(totalSupplyPos())
            }
            function balanceOf(account) -> bal {
                bal := sload(accountToStorageOffset(account))
            }
            function allowance(account, spender) -> amount {
                amount := sload(allowanceStorageOffset(account, spender))
            }
            
            // !SECTION

            // SECTION Storage write access
            function mintTokens(amount) {
                sstore(totalSupplyPos(), safeAdd(totalSupply(), amount))
            }
            function burnTokens(amount) {
                sstore(totalSupplyPos(), safeSub(totalSupply(), amount))
            }
            function setAllowance(account, spender, amount) {
                sstore(allowanceStorageOffset(account, spender), amount)
            }
            function decreaseAllowanceBy(account, spender, amount) {
                let offset := allowanceStorageOffset(account, spender)
                let currentAllowance := sload(offset)
                require(lte(amount, currentAllowance))
                sstore(offset, sub(currentAllowance, amount))
            }
            function addToBalance(account, amount) {
                let offset := accountToStorageOffset(account)
                sstore(offset, safeAdd(sload(offset), amount))
            }
            function deductFromBalance(account, amount) {
                let offset := accountToStorageOffset(account)
                let bal := sload(offset)
                require(lte(amount, bal))
                sstore(offset, sub(bal, amount))
            }
            // !SECTION

            // SECTION Utilities


            function lte(a, b) -> r {
                r := iszero(gt(a, b))
            }
            function gte(a, b) -> r {
                r := iszero(lt(a, b))
            }
            function calledByOwner() -> cbo {
                cbo := eq(owner(), caller())
            }
            function revertIfZeroAddress(addr) {
                require(addr)
            }
            // !SECTION

            // ANCHOR Main cycle checker
            switch selector()
            // SECTION Public functions calling 
            case 0x70a08231  /*balanceOf(address)*/  {
                returnUint(balanceOf(decodeAsAddress(0)))
            }
            case 0x18160ddd  /*totalSupply()*/  {
                returnUint(totalSupply())
            }
            case 0xa9059cbb  /*transfer(address,uint256)*/  {
                transfer(decodeAsAddress(0), decodeAsUint(1))
                returnUint(1)
            }
            case 0x23b872dd  /*transferFrom(address,address,uint256)*/  {
                transferFrom(decodeAsAddress(0), decodeAsAddress(1), decodeAsUint(2))
                returnUint(1)
            }
            case 0x095ea7b3  /*approve(address,uint256)*/  {
                approve(decodeAsAddress(0), decodeAsUint(1))
                returnUint(1)
            }
            case 0xdd62ed3e  /*allowance(address,address)*/  {
                returnUint(allowance(decodeAsAddress(0), decodeAsAddress(1)))
            }
            case 0x40c10f19  /*mint(address,uint256)*/  {
                mint(decodeAsAddress(0), decodeAsUint(1))
                returnUint(1)
            }
            // NOTE This is fundamental to avoid calling of private functions
            default {
                revert(0, 0)
            }
            // !SECTION
        }
    }
    // !SECTION


 // SECTION Payable
    receive() external payable {
        assembly {
            // ANCHOR require asm definition
             function require(condition) {
                if iszero(condition) { revert(0, 0) }
            }
            // NOTE Payable
            require(not(iszero(callvalue())))
        }
    }
    // !SECTION

}