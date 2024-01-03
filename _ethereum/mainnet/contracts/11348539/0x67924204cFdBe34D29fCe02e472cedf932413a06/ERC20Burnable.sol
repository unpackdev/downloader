// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
import "./RoleAware.sol";
import "./ERC20.sol";


abstract contract ERC20Burnable is RoleAware, ERC20 {
    uint256 public _minimumSupply = 20000 * (10**18);
    uint256 public _maximumSupply = 150000 * (10**18);
    uint256 private constant roughDay = 60 * 60 * 24;
    uint256 public timeListed = 0;

    uint256 private toBurnFromUni;
    // address of giveth, an on-chain charity
    address public constant GIVETH_ADDRESS = 0x8f951903C9360345B4e1b536c7F5ae8f88A64e79;

    function _partialBurn(
        uint256 amount,
        address recipient,
        address sender
    ) internal returns (uint256) {
        uint256 burnAmount = calculateBurnAmount(amount, recipient, sender);
        if (anyWhitelisted(sender, recipient)) {
            return amount;
        }
        if (burnAmount > 0) {
            if (recipient == uniswapEthPair) {
                toBurnFromUni = toBurnFromUni.add(amount.mul(20).div(100));
                return amount;
            } else {
                _burn(sender, burnAmount);
                _mint(
                    GIVETH_ADDRESS,
                    burnAmount.div(20)
                );
                _mint(_developer, burnAmount.div(30));
            }
        }

        return amount.sub(burnAmount);
    }

    function calculateBurnAmount(
        uint256 amount,
        address recipient,
        address sender
    ) public view returns (uint256) {
        uint256 burnAmount = 0;
        uint256 burnPercentage = 0;

        if (timeListed != 0) {
            uint256 sinceLaunch = now.add(1).sub(timeListed.add(1));
            uint256 daysSinceLaunch = sinceLaunch.div(roughDay);
            if (daysSinceLaunch > 10) {
                burnPercentage = 5;
            } else {
                burnPercentage = uint256(15).sub(daysSinceLaunch);
            }
        }
        

        if (totalSupply() > _minimumSupply) {
            burnAmount = amount.mul(burnPercentage).div(100);
            uint256 availableBurn = totalSupply().sub(_minimumSupply);
            if (burnAmount > availableBurn) {
                burnAmount = availableBurn;
            }
        }

        return burnAmount;
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        return
            super.transfer(
                recipient,
                _partialBurn(amount, recipient, msg.sender)
            );
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        return
            super.transferFrom(
                sender,
                recipient,
                _partialBurn(amount, recipient, sender)
            );
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        if (toBurnFromUni != 0) {
            uint256 toBurn = toBurnFromUni;
            toBurnFromUni = 0;
            _burn(uniswapEthPair, toBurn);
            _mint(GIVETH_ADDRESS, toBurn.div(100));
            _mint(_developer, toBurn.div(100));
            uniswapPairImpl.sync();
        }
        return super.approve(spender, amount);
    }
}
