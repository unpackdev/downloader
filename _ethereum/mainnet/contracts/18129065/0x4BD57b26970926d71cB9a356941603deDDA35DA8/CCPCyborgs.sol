// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./EasyMintLogic.sol";
import "./Strings.sol";
import "./EasyLibrary.sol";

/// @author developer's website 🐸 https://www.halfsupershop.com/ 🐸
contract CCPCyborgs is EasyMintLogic {
    using EasyLibrary for *;
    string private hiddenURI;
    mapping(uint => string) private tokenToURI;

    address payable public payments;

    mapping(uint256 => bool) public flagged; //flagged tokens cannot be moved
    mapping(address => bool) public restricted; //restricted addresses cannot move tokens

    error Flagged();
    error Restricted();
    /* 
    address(0) = 0x0000000000000000000000000000000000000000
    */

    constructor() EasyInit(msg.sender){
        name = "Crypto Cloud Punks Cyborgs";
        symbol = "CCPCY";
    }

    /**
    @dev Sets the URI for a token or batch of tokens.
    @param _hidden Flag to determine if the URI should be set as the hidden URI.
    @param _tier Flag to determine if the URI should be set as the tier URI.
    @param _isBatch Flag to determine if a batch of tokens is being modified.
    @param _id ID of the token or batch of tokens being modified.
    @param _uriPS[] The new URI to be set 0 = Prefix, 1 = Suffix.
    */
    function setURI(bool _hidden, bool _tier, bool _isBatch, uint _id, string[2] memory _uriPS) external onlyAdmins {
        if (_hidden) {
            hiddenURI = _uriPS[0];
            return;
        }

        if (_tier) {
            tierURI = _uriPS[0];
            return;
        }

        if (!_isBatch) {
            tokenToURI[_id] = _uriPS[0];
            emit URI(_uriPS[0], _id);
        }
        else{
            //modify Batch URI
            batchData[_id].bURI = _uriPS;
        }
    }

    /**
    @dev Returns the URI for a given token ID. If the token is a collection,
    the URI may be batched. If the token batch has roll enabled, it will have
    a random roll id. If the token is not found, the URI defaults to a hidden URI.
    @param _id uint256 ID of the token to query the URI of
    @return string representing the URI for the given token ID
    */
    function uri(uint256 _id) override public view returns (string memory) {
        // Check if token is created
        if (!createdToken[_id] || _id > collectionEndID) {
            // Not found, default to hidden
            return hiddenURI;
        }

        // Check if URI is set for the token
        if (bytes(tokenToURI[_id]).length > 0) {
            return tokenToURI[_id];
        }

        // Iterate through batch IDs
        for (uint256 i = 0; i < batchData.length; i++) {
            if (_id >= batchData[i].bRangeNext[0] && _id <= batchData[i].bRangeNext[1]) {
                if (!batchData[i].bRevealed) {
                    return hiddenURI;
                }

                // Check if the token has a roll
                if (bytes(roll[_id]).length > 0) {
                    return string(abi.encodePacked(batchData[i].bURI[0], roll[_id], "/", Strings.toString(_id), batchData[i].bURI[1]));
                }

                // Token doesn't have a roll
                return string(abi.encodePacked(batchData[i].bURI[0], Strings.toString(_id), batchData[i].bURI[1]));
            }
        }

        // Token is beyond the last batch, return hidden URI
        return hiddenURI;
    }

    /**
    @dev Allows admin to set the payout address for the contract.
    @param _address The new payout address to set.
    Note: address can be a wallet or a payment splitter contract
    */
    function setPayoutAddress(address _address) external onlyOwner{
        payments = payable(_address);
    }

    /**
    @dev Admin can withdraw the contract's balance to the specified payout address.
    The `payments` address must be set before calling this function.
    The function will revert if `payments` address is not set or the transaction fails.
    */
    function withdraw() public onlyAdmins {
        require(payments != address(0), "Payout address not set");

        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        // Splitter
        (bool success, ) = payable(payments).call{ value: balance }("");
        require(success, "Withdrawal failed");
    }

    /**
    @dev Auto send funds to the payout address.
    Triggers only if funds were sent directly to this address.
    */
    receive() external payable {
        require(payments != address(0), "Payment address not set");
        uint256 payout = msg.value;
        payments.transfer(payout);
    }

    /**
    * @dev Owner or Project Leader can set the restricted state of an address.
    * Note: Restricted addresses are banned from moving tokens.
    */
    function restrictAddress(address _user, bool _state) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "NOoPL");
        restricted[_user] = _state;
    }

    /**
    * @dev Owner or Project Leader can set the flag state of a token ID.
    * Note: Flagged tokens are locked and untransferable.
    */
    function flagID(uint256 _id, bool _state) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "NOoPL");
        flagged[_id] = _state;
    }

    /**
    * @dev Check if an ID is in a bind on mint batch.
    */
    function bindOnMint(uint _id) public view returns(bool){
        uint256 _batchID;
        if (batchData.length > 0) {
            for (uint256 i = 0; i < batchData.length; i++) {
                if (_id >= batchData[i].bRangeNext[0] && _id <= batchData[i].bRangeNext[1]) {
                    _batchID = i;
                }
            }
            return batchData[_batchID].bBindOnMint;
        }
        return false;
    }

    /**
    * @dev Hook that is called for any token transfer. 
    * This includes minting and burning, as well as batched variants.
    */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory amounts) internal virtual override {
        // ... before action here ...
        if (restricted[from] || restricted[to]) {
            revert Restricted();
        }

        for (uint256 i = 0; i < ids.length; i++) {
            if (flagged[ids[i]]) {
                revert Flagged(); //reverts if a token has been flagged
            }
        }
        
        super._update(from, to, ids, amounts); // Call parent hook

        // ... after action here ...
        for (uint256 i = 0; i < ids.length; i++) {
            if (bindOnMint(ids[i])) {
                flagged[ids[i]] = true;
            }

            if (to == address(0)) {
                //burned tokens
                uint256 _id = ids[i];
                currentSupply[_id] -= amounts[i];
            }
        }   
    }
}