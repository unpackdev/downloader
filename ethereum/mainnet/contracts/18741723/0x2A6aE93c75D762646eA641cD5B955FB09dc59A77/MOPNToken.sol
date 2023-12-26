// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./console.sol";

import "./IMOPNGovernance.sol";
import "./IMOPN.sol";
import "./IMOPNData.sol";
import "./IERC20Receiver.sol";
import "./ERC20Burnable.sol";
import "./Multicall.sol";

/*
.___  ___.   ______   .______   .__   __. 
|   \/   |  /  __  \  |   _  \  |  \ |  | 
|  \  /  | |  |  |  | |  |_)  | |   \|  | 
|  |\/|  | |  |  |  | |   ___/  |  . `  | 
|  |  |  | |  `--'  | |  |      |  |\   | 
|__|  |__|  \______/  | _|      |__| \__| 
*/
contract MOPNToken is ERC20Burnable, Multicall {
    /**
     * @dev Magic value to be returned by ERC20Receiver upon successful reception of token(s)
     * @dev Equal to `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))`,
     *      which can be also obtained as `ERC20Receiver(0).onERC20Received.selector`
     */
    bytes4 private constant ERC20_RECEIVED = 0x4fc35859;

    IMOPNGovernance governance;

    modifier onlyMOPN() {
        require(
            msg.sender == governance.mopnContract() ||
                msg.sender == governance.auctionHouseContract(),
            "MOPNToken: Only MOPN contract can call this function"
        );
        _;
    }

    constructor(address governance_) ERC20("MOPN Token", "MT") {
        governance = IMOPNGovernance(governance_);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) public onlyMOPN {
        _mint(to, amount);
    }

    function mopnburn(address from, uint256 amount) public onlyMOPN {
        _burn(from, amount);
    }

    function createCollectionVault(address collectionAddress) public {
        governance.createCollectionVault(collectionAddress);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data
    ) public {
        if (_from == msg.sender) {
            _transfer(_from, _to, _value);
        } else {
            transferFrom(_from, _to, _value);
        }

        // after the successful transfer – check if receiver supports
        // ERC20Receiver and execute a callback handler `onERC20Received`,
        // reverting whole transaction on any error:
        // check if receiver `_to` supports ERC20Receiver interface
        if (_to.code.length > 0) {
            // if `_to` is a contract – execute onERC20Received
            bytes4 response = IERC20Receiver(_to).onERC20Received(
                msg.sender,
                _from,
                _value,
                _data
            );

            // expected response is ERC20_RECEIVED
            require(response == ERC20_RECEIVED);
        }
    }

    function totalSupply() public view override returns (uint256) {
        IMOPN mopn = IMOPN(governance.mopnContract());
        return
            mopn.MTTotalMinted() +
            (IMOPNData(governance.dataContract()).calcPerMOPNPointMinted() -
                mopn.PerMOPNPointMinted()) *
            mopn.TotalMOPNPoints();
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256 balance) {
        balance = super.balanceOf(account);
        balance += IMOPNData(governance.dataContract()).calcAccountMT(account);
    }

    function _beforeTokenTransfer(
        address from,
        address,
        uint256
    ) internal virtual override {
        IMOPN mopn = IMOPN(governance.mopnContract());
        IMOPN.AccountDataStruct memory accountData = mopn.getAccountData(from);
        if (accountData.Coordinate > 0) {
            mopn.claimAccountMT(from);
        }
    }
}
