// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.15;

/* Resources on YUL programming */

// LINK https://medium.com/@jtriley15/yul-vs-solidity-contract-comparison-2b6d9e9dc833
// LINK https://github.com/FuelLabs/yulp
// LINK https://hackernoon.com/programming-tutorial-getting-started-with-yul
// LINK https://github.com/FuelLabs/yulp/tree/master/examples
// LINK https://docs.soliditylang.org/en/v0.8.9/yul.html#specification-of-yul
// LINK https://mirror.xyz/0xB38709B8198d147cc9Ff9C133838a044d78B064B/Hh69VJWM5eiFYFINxYWrIYWcRRtPm8tw3VFjpdpx6T8


// ANCHOR Interface for ERC20
interface ERC20 {
    
  function balanceOf(address _owner) external view returns (uint256 balance);

  function transfer(address _to, uint256 _value)
    external
    returns (bool success);

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) external returns (bool success);

  function approve(address _spender, uint256 _value)
    external
    returns (bool success);

  function allowance(address _owner, address _spender)
    external
    view
    returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );
}

// ANCHOR Contract begin

// SECTION Interface-compliant routing to assembly

contract ASM20Routing is ERC20 {

    receive() external payable {}

    fallback() external payable {}

    // SECTION Constructor
    constructor() {
        assembly {
            sstore(0, caller())
            // ANCHOR Setting initial supply
            sstore(1, 1000000000000000000000000000) // 1 billion with 18 decimals
        }
    }
    // !SECTION

    // SECTION Token properties
    function name() public pure returns (string memory _name_) {
        assembly {
            _name_ := "ASM20 Routed"
        }
    }

    function symbol() public pure returns (string memory _symbol_) {
        assembly {
            _symbol_ := "ASM20R"
        }
    }
    // !SECTION

    // SECTION Writes
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        assembly {
            function require(condition) {
                    if iszero(condition) { revert(0, 0) }
            }

            /**** Allowance instructions ****/

            let _spender := caller()
            // Get allowance
            let offset := add(0x1000, _from)
            mstore(0, offset)
            mstore(0x20, _spender)
            offset := keccak256(0, 0x40)
            let remaining := sload(offset)
            require(gt(remaining, _value))
            // Subtract allowance
            sstore(offset, sub(remaining, _value))

            /**** Transfer instructions ****/

            // Increase balance of `_to`
            offset := add(0x1000, _to)
            let bal := sload(offset)
            let sum := add(sload(offset), _value)
            require(or(eq(sum,sload(offset)), gt(sum,sload(offset))))
            sstore(offset, sum)
            // Decrease balance of `_from`
            offset := add(0x1000, _from)
            bal := sload(offset)
            require(iszero(gt(_value, bal)))
            sstore(offset, sub(bal, _value))
            // Emit Transfer event
            let signatureHash := 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
            mstore(0, _value)
            log3(0, 0x20, signatureHash, _from, _to)
            success := true
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        assembly {
            function require(condition) {
                    if iszero(condition) { revert(0, 0) }
            }
            // Get _from 
            let _from := caller()
            // Increase balance of `_to`
            let offset := add(0x1000, _to)
            let bal := sload(offset)
            let sum := add(sload(offset), _value)
            require(or(eq(sum,sload(offset)), gt(sum,sload(offset))))
            sstore(offset, sum)
            // Decrease balance of `_from`
            offset := add(0x1000, _from)
            bal := sload(offset)
            require(iszero(gt(_value, bal)))
            sstore(offset, sub(bal, _value))
            // Emit Transfer event
            let signatureHash := 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
            mstore(0, _value)
            log3(0, 0x20, signatureHash, _from, _to)
            success := true
        }
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        assembly {
            function require(condition) {
                    if iszero(condition) { revert(0, 0) }
            }
            require(_spender)
            // Get approver account offset
            let account := caller()
            let offset := add(0x1000, account)
            // Get spender account offset
            mstore(0, offset)
            mstore(0x20, _spender)
            offset := keccak256(0, 0x40)
            // Set allowance
            sstore(offset, _value)
            // Emit Approval event
            let signatureHash := 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925
            mstore(0, _value)
            log3(0, 0x20, signatureHash, account, _spender)
            success := true
        }
    }
    // !SECTION

    // SECTION Internal writes
    function increaseBalance(address _owner, uint256 _amount) internal {
        assembly {
            function require(condition) {
                    if iszero(condition) { revert(0, 0) }
            }

            let offset := add(0x1000, _owner)
            let bal := sload(offset)
            let sum := add(sload(offset), _amount)
            require(or(eq(sum,sload(offset)), gt(sum,sload(offset))))
            sstore(offset, sum)
        }
    }

    function decreaseBalance(address _owner, uint256 _amount) internal {
        assembly {
            function require(condition) {
                    if iszero(condition) { revert(0, 0) }
            }

            let offset := add(0x1000, _owner)
            let bal := sload(offset)
            require(iszero(gt(_amount, bal)))
            sstore(offset, sub(bal, _amount))
        }
    }
    // !SECTION

    // SECTION Views 
    function owner() public view returns (address _owner_) {
            assembly {
                _owner_ := sload(0)
            }
    }

    function balanceOf(address _owner) public view returns (uint256 _balance_) {
            assembly {
                _balance_ := sload(add(0x1000, _owner))
            }
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        assembly {
                let offset := add(0x1000, _owner)
                mstore(0, offset)
                mstore(0x20, _spender)
                offset := keccak256(0, 0x40)
                remaining := sload(offset)
            }
        }
    

    function totalSupply() public view returns (uint256 _totalSupply_) {
        assembly {
            _totalSupply_ := sload(1)
        }
    }

    function decimals() public pure returns (uint8 _decimals_) {
        assembly {
            _decimals_ := 18
        }
    }
    // !SECTION

    // SECTION Events
        function TRANSFER(address _from, address _to, uint256 _value) public {
            assembly {
                    let signatureHash := 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
                    mstore(0, _value)
                    log3(0, 0x20, signatureHash, _from, _to)
                }
        }

        function APPROVAL(address from, address spender, address amount) public {
            assembly {
                let signatureHash := 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925
                mstore(0, amount)
                log3(0, 0x20, signatureHash, from, spender)
            }
        }
        // !SECTION
}
// !SECTION