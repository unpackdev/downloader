// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";

import "./IUniswapV2Pair.sol";

import "./ITransferRules.sol";
import "./ISRC20.sol";

abstract contract BaseTransferRule is Initializable, OwnableUpgradeable, ITransferRules {
    address public chainRuleAddr;
    address public _src20;
    address public doTransferCaller;
    
    
    modifier onlyDoTransferCaller {
        require(msg.sender == address(doTransferCaller));
        _;
    }
    
    //---------------------------------------------------------------------------------
    // public  section
    //---------------------------------------------------------------------------------
    function cleanSRC() public onlyOwner() {
        _src20 = address(0);
        doTransferCaller = address(0);
        //_setChain(address(0));
    }
    
    function clearChain() public onlyOwner() {
        _setChain(address(0));
    }
    
    function setChain(address chainAddr) public onlyOwner() {
        _setChain(chainAddr);
        require(_tryExternalSetSRC(_src20), "can't call setSRC at chain contract");
        
    }
    
    
    //---------------------------------------------------------------------------------
    // external  section
    //---------------------------------------------------------------------------------
    /**
    * @dev Set for what contract this rules are.
    *
    * @param src20 - Address of src20 contract.
    */
    function setSRC(address src20) override external returns (bool) {
        require(doTransferCaller == address(0), "external contract already set");
        require(address(_src20) == address(0), "external contract already set");
        require(src20 != address(0), "src20 can not be zero");
        doTransferCaller = _msgSender();
        _src20 = src20;
        return true;
    }
     /**
    * @dev Do transfer and checks where funds should go. If both from and to are
    * on the whitelist funds should be transferred but if one of them are on the
    * grey list token-issuer/owner need to approve transfer.
    *
    * param from The address to transfer from.
    * param to The address to send tokens to.
    * @param value The amount of tokens to send.
    */
    function doTransfer(address from, address to, uint256 value) override external onlyDoTransferCaller returns (bool) {
        (from,to,value) = _doTransfer(from, to, value);
        if (isChainExists()) {
            require(ITransferRules(chainRuleAddr).doTransfer(msg.sender, to, value), "chain doTransfer failed");
        } else {
            //_transfer(msg.sender, to, value);
            require(ISRC20(_src20).executeTransfer(from, to, value), "SRC20 transfer failed");
        }
        return true;
    }
    //---------------------------------------------------------------------------------
    // internal  section
    //---------------------------------------------------------------------------------
    function __BaseTransferRule_init() internal initializer {
        __Ownable_init();

    }
    function isChainExists() internal view returns(bool) {
        return (chainRuleAddr != address(0) ? true : false);
    }
    
    function _doTransfer(address from, address to, uint256 value) internal virtual returns(address _from, address _to, uint256 _value) ;
    
    //---------------------------------------------------------------------------------
    // private  section
    //---------------------------------------------------------------------------------

    function _tryExternalSetSRC(address chainAddr) private returns (bool) {
        try ITransferRules(chainAddr).setSRC(_src20) returns (bool) {
            return (true);
        } catch Error(string memory /*reason*/) {
            // This is executed in case
            // revert was called inside getData
            // and a reason string was provided.
            
            return (false);
        } catch (bytes memory /*lowLevelData*/) {
            // This is executed in case revert() was used
            // or there was a failing assertion, division
            // by zero, etc. inside getData.
            
            return (false);
        }
        
    }
    
    function _setChain(address chainAddr) private {
        chainRuleAddr = chainAddr;
    }
    
}
    