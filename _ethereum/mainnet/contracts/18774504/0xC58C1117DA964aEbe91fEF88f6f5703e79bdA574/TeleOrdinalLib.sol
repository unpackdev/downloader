// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "./Address.sol";
import "./BitcoinHelper.sol";
import "./ScriptTypesEnum.sol";

library TeleOrdinalLib {

    // Structures

    /// @notice Structure for passing signature
    /// @param bitcoinPubKey Bitcoin PubKey of the Ordinal holder (without starting '04'). 
    ///                      Don't need to be passed in the case of Taproot
    /// @param r Part of signature (or `e` = schnorr sig challenge)
    /// @param s Part of signature
    /// @param v is needed for recovering the public key (it can be 27 or 28)
	struct Signature {
        bytes bitcoinPubKey;
        bytes32 r;
        bytes32 s;
        uint8 v;
  	}

    /// @notice Structure for passing Bitcoin tx to functions
    /// @param version Versions of tx
    /// @param vin Inputs of tx
    /// @param vout Outputs of tx
    /// @param locktime Locktimes of tx
	struct Tx {
        bytes4 version;
		bytes vin;
		bytes vout;
		bytes4 locktime;
  	}

    /// @notice Structure for passing Merkle proofs
    /// @param blockNumber Height of the block containing tx
    /// @param intermediateNodes Merkle inclusion proof for tx
    /// @param index Index of tx in the block
	struct MerkleProof {
    	uint256 blockNumber;
		bytes intermediateNodes;
		uint index;
  	}

    /// @notice Structure for passing Ordinal's location
    /// @param txId of the Ordinal
    /// @param outputIdx Index of the output that includes Ordinal
    /// @param satoshiIdx Index of the inscribed satoshi in the output satoshis
	struct Loc {
        bytes32 txId;
        uint outputIdx; 
        uint satoshiIdx;
  	}

    /// @notice Structure for storing Ordinal data
    /// @param seller Address of seller 
    /// @param isSold True if the Ordinal is sold
    /// @param hasAccepted True if the seller accepted one of the bids
    /// @param sellerScript Script hash of seller on Bitcoin
    /// @param scriptType Type of seller's script (e.g. P2PKH)
	struct Ordinal {
        address seller;
        bool isSold;
        bool hasAccepted;
        bool isListed;
        bytes sellerScript;
        ScriptTypes scriptType;
  	}

    /// @notice Structure for recording buyers bids
    /// @param buyerBTCScript Seller will send the Ordinal to the provided script
    /// @param buyerETHAddress Buyer can withdraw ETH to this address
    /// @param bidAmount Amount of buyre's bid
    /// @param deadline Buyer cannot withdraw funds before deadline (it is based on the bitcoin block number)    		
    /// @param isAccepted True if the bid is accepted by seller
    /// @param paymentToken Address of token that buyer uses for payment
	struct Bid {
		bytes buyerBTCScript;
        ScriptTypes buyerScriptType;
		address buyerETHAddress;
		uint bidAmount;
        uint deadline;
        bool isAccepted;
        address paymentToken;
  	}

    bytes constant MAGIC_BYTES = "Bitcoin Signed Message:\n";
    bytes1 constant public FOUR = 0x04;    
    uint256 constant public Q = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141; 
    // ^ secp256k1 group order


    function listOrdinalHelper(
        ScriptTypes _scriptType,
        Signature calldata _signature,
        Tx calldata _tx,
        Loc calldata _loc,
        mapping(bytes32 => mapping(uint => mapping(uint => Ordinal))) storage ordinals,
        bool _isSignRequired,
        address _seller
    ) external returns (bytes memory _scriptHash) {
        require(
            BitcoinHelper.calculateTxId(_tx.version, _tx.vin, _tx.vout, _tx.locktime) ==
                _loc.txId,
            "TeleOrdinal: wrong txId"
        );
        require(
            !ordinals[_loc.txId][_loc.outputIdx][_loc.satoshiIdx].isListed, 
            "TeleOrdinal: already listed"
        );
        
        // Extracts script hash of seller from the output that includes the Ordinal
        _scriptHash = _findScriptHash(
            _scriptType, 
            BitcoinHelper.getLockingScript(_tx.vout, _loc.outputIdx) // lockingScript
        );

        // If isSignRequired, seller should provide a valid signature to list Ordinal 
        // (with the same public key that holds the Ordinal)
        if (_isSignRequired) {
            _checkSignature(_scriptType, _scriptHash, _msgHash(_seller), _signature);
        }

        // Saves listed Ordinal
        Ordinal memory _ordinal;
        _ordinal.seller = _seller;
        _ordinal.isListed = true;
        _ordinal.sellerScript = _scriptHash;
        _ordinal.scriptType = _scriptType;
        ordinals[_loc.txId][_loc.outputIdx][_loc.satoshiIdx] = _ordinal;
    }

    function delistOrdinalHelper(
        Loc calldata _loc,
        mapping(bytes32 => mapping(uint => mapping(uint => Ordinal))) storage ordinals,
        address _seller
    ) external view {
        require(ordinals[_loc.txId][_loc.outputIdx][_loc.satoshiIdx].isListed, "TeleOrdinal: no ordinal");
        require(ordinals[_loc.txId][_loc.outputIdx][_loc.satoshiIdx].seller == _seller, "TeleOrdinal: not owner");
        require(!ordinals[_loc.txId][_loc.outputIdx][_loc.satoshiIdx].isSold, "TeleOrdinal: already sold");
        require(!ordinals[_loc.txId][_loc.outputIdx][_loc.satoshiIdx].hasAccepted, "TeleOrdinal: already accepted");
    }

    function putBidHelper(
        Loc calldata _loc,
        bytes memory _buyerBTCScript,
        ScriptTypes _scriptType,
        mapping(bytes32 => mapping(uint => mapping(uint => Ordinal))) storage ordinals
    ) external view {
        _canBid(
            ordinals[_loc.txId][_loc.outputIdx][_loc.satoshiIdx].isListed, 
            ordinals[_loc.txId][_loc.outputIdx][_loc.satoshiIdx].hasAccepted,
            ordinals[_loc.txId][_loc.outputIdx][_loc.satoshiIdx].isSold
        );

        // Checks that the script is valid 
        _checkScriptType(_buyerBTCScript, _scriptType);
    }

    function increaseBidHelper(
        Loc calldata _loc,
        uint _bidIdx,
        uint _newAmount,
        mapping(bytes32 => mapping(uint => mapping(uint => Ordinal))) storage ordinals,
        mapping(bytes32 => mapping(uint => mapping(uint => Bid[]))) storage bids,
        address _seller
    ) external view {
        _canBid(
            ordinals[_loc.txId][_loc.outputIdx][_loc.satoshiIdx].isListed, 
            ordinals[_loc.txId][_loc.outputIdx][_loc.satoshiIdx].hasAccepted,
            ordinals[_loc.txId][_loc.outputIdx][_loc.satoshiIdx].isSold
        );

        require(
            bids[_loc.txId][_loc.outputIdx][_loc.satoshiIdx][_bidIdx].buyerETHAddress == _seller, 
            "TeleOrdinal: not owner"
        );
        require(
            _newAmount > bids[_loc.txId][_loc.outputIdx][_loc.satoshiIdx][_bidIdx].bidAmount, 
            "TeleOrdinal: low amount"
        );
    }

    /// @notice Finds the index of Ordinal in the input of transfer tx
    /// @param _loc Location of the Ordinal (txId, outputIdx, satoshiIdx)
    /// @param _vin inputs of transaction that transffred Ordinal from seller to buyer
    /// @param _inputTxs List of all transactions that were spent by _transferTx before the input that spent the Ordinal
    function ordinalIdxInInputSats(
        Loc calldata _loc,
        bytes memory _vin,
        Tx[] memory _inputTxs
    ) external pure returns (uint _idx) {
        bytes32 _outpointId;
        uint _outpointIndex;
        
        // Sum of inputs in transferTx (before the input that spent Ordinal)
        for (uint i = 0; i < _inputTxs.length; i++) {
            (_outpointId, _outpointIndex) = BitcoinHelper.extractOutpoint(
                _vin,
                i
            );

            // Checks that "outpoint tx id == input tx id"
            // Makes sure that the provided input txs are valid
            require(
                _outpointId == BitcoinHelper.calculateTxId(
                    _inputTxs[i].version, 
                    _inputTxs[i].vin, 
                    _inputTxs[i].vout, 
                    _inputTxs[i].locktime
                ),
                "TeleOrdinal: outpoint != input tx"
            );

            _idx += BitcoinHelper.parseOutputValue(_inputTxs[i].vout, _outpointIndex);
        }

        (_outpointId, _outpointIndex) = BitcoinHelper.extractOutpoint(
            _vin,
            _inputTxs.length // this is the input that spent the Ordinal
        );

        // Checks that "outpoint tx id == _txId"
        require(
            (_outpointId == _loc.txId) && (_outpointIndex == _loc.outputIdx),
            "TeleOrdinal: outpoint not match with _txId"
        );

        // Finds the positon of Ordinal in input of transfer tx
        _idx += _loc.satoshiIdx;
    }

    /// @notice Checks that weather the Ordinal is transferred to buyer or not
    /// @param _loc Old location of the Ordinal (txId, outputIdx, satoshiIdx)
    /// @param _bidIdx Index of the accepted bid in bids list
    /// @param _vout output of transaction that transffred Ordinal from seller to buyer
    /// @param _newLoc New location of the Ordinal (txId, outputIdx, satoshiIdx)
    /// @param _ordinalIdxInInputSats Index of Ordinal in input sats
    function checkOrdinalTransfer(
        TeleOrdinalLib.Loc calldata _loc,
        uint _bidIdx,
        bytes memory _vout,
        TeleOrdinalLib.Loc calldata _newLoc,
        uint _ordinalIdxInInputSats,
        mapping(bytes32 => mapping(uint => mapping(uint => Bid[]))) storage bids
    ) external view {
        // Finds number of satoshis before the output that includes the Ordinal
        uint outputValue;
        for (uint i = 0; i < _newLoc.outputIdx; i++) {
            outputValue += BitcoinHelper.parseOutputValue(_vout, i);
        }

        if (_newLoc.outputIdx != 0) {
            require(
                _ordinalIdxInInputSats + 1 > outputValue, // 1 is added bcz index starts from 0
                "TeleOrdinal: not transferred"
            );
        }

        require(
            _ordinalIdxInInputSats + 1 <= outputValue + BitcoinHelper.parseValueFromSpecificOutputHavingScript(
                _vout,
                _newLoc.outputIdx,
                bids[_loc.txId][_loc.outputIdx][_loc.satoshiIdx][_bidIdx].buyerBTCScript,
                bids[_loc.txId][_loc.outputIdx][_loc.satoshiIdx][_bidIdx].buyerScriptType
            ),
            "TeleOrdinal: not transferred"
        );

        require(
            _ordinalIdxInInputSats == outputValue + _newLoc.satoshiIdx,
            "TeleOrdinal: wrong satoshiIdx"
        );
    }

    /// @notice Checks the bidding conditions
    /// @dev Conditions for bidding: Ordinal exists, no offer accepted, not sold
    function _canBid(
        bool _isListed,
        bool _hasAccepted,
        bool _isSold
    ) private pure {
        require(_isListed, "TeleOrdinal: not listed");
        require(!_hasAccepted, "TeleOrdinal: already accepted");
        require(!_isSold, "TeleOrdinal: sold ordinal");
    }

    function _findScriptHash(
        ScriptTypes _scriptType,
        bytes memory lockingScript
    ) private pure returns (bytes memory scriptHash) {
        if (_scriptType == ScriptTypes.P2TR) { 
            // locking script = OP_1 (1 byte) 20 (1 byte) PUB_KEY (32 bytes)
            scriptHash = _sliceBytes(lockingScript, 2, 33);
        } else if (_scriptType == ScriptTypes.P2WPKH) { 
            // locking script = ZERO (1 byte) PUB_KEY_HASH (20 bytes)
            scriptHash = _sliceBytes(lockingScript, 1, 20);
        } else if (_scriptType == ScriptTypes.P2PKH) { 
            // locking script = OP_DUP (1 byte) OP_HASH160 (2 bytes) PUB_KEY_HASH (20 bytes)  OP_EQUALVERIFY OP_CHECKSIG
            scriptHash = _sliceBytes(lockingScript, 3, 22);
        } else if (_scriptType == ScriptTypes.P2PK) { 
            // locking script = PUB_KEY (65 bytes) OP_CHECKSIG
            scriptHash = _sliceBytes(lockingScript, 0, 64);
        } else {
            revert("TeleOrdinal: invalid type");
        }
    }

    function _checkSignature(
        ScriptTypes _scriptType,
        bytes memory _scriptHash,
        bytes32 _hash,
        Signature memory _signature
    ) private pure {
        require(_signature.bitcoinPubKey.length == 64 || _signature.bitcoinPubKey.length == 0, "invalid pub key");
        // ^ 0 for taproot, 64 for other cases

        if (_scriptType == ScriptTypes.P2TR) {
            require(
                _verifySchnorr(_convertToBytes32(_scriptHash), _hash, _signature),
                "TeleOrdinal: not ordinal owner"
            );
        } else {
            require(
                _compareBytes(
                    _scriptHash, _doubleHash(abi.encodePacked(FOUR, _signature.bitcoinPubKey))
                ),
                "TeleOrdinal: wrong pub key"
            );

            // check that the signature for txId is valid
            // etherum address = last 20 bytes of hash(pubkey)
            require(
                _bytesToAddress(
                    _sliceBytes(
                        abi.encodePacked(keccak256(_signature.bitcoinPubKey)), 
                        12, 
                        31
                    )
                ) == ecrecover(_hash, _signature.v, _signature.r, _signature.s),
                "TeleOrdinal: not ordinal owner"
            );
        }
    }

    /// @notice Checks that the bitcoin script provided by buyer is valid (so seller can send the btc to it)
    /// @param _script seller locking script (without op codes)
    /// @param _scriptType type of locking script (e.g. P2PKH, P2TR)
    function _checkScriptType(bytes memory _script, ScriptTypes _scriptType) private pure {
        if (_scriptType == ScriptTypes.P2PK || _scriptType == ScriptTypes.P2WSH || _scriptType == ScriptTypes.P2TR) {
            require(_script.length == 32, "TeleOrdinal: invalid script");
        } else {
            require(_script.length == 20, "TeleOrdinal: invalid script");
        }
    }

    /// @notice Determines the hash that should be signed by user
    /// @dev This hash is generated based on the seller address, so it cannot be used by others
    function _msgHash(address _seller) private pure returns (bytes32) {
        string memory _sellerString = _addressToString(_seller);
        bytes memory prefix1 = _toVarintBufNum(MAGIC_BYTES.length);
        bytes memory messageBuffer = abi.encodePacked(_sellerString);
        bytes memory prefix2 = _toVarintBufNum(messageBuffer.length);
        bytes memory buf = abi.encodePacked(prefix1, MAGIC_BYTES, prefix2, messageBuffer);
        return sha256(abi.encodePacked(sha256(buf)));
    }

    function _addressToString(address _addr) private pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_addr)));

        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[12 + i] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[12 + i] & 0x0f)];
        }

        return string(str);
    }

    function _toVarintBufNum(uint256 num) private pure returns (bytes memory) {
        if (num < 0xfd) {
            return abi.encodePacked(uint8(num));
        } else if (num <= 0xffff) {
            return abi.encodePacked(uint8(0xfd), uint16(num));
        } else if (num <= 0xffffffff) {
            return abi.encodePacked(uint8(0xfe), uint32(num));
        } else {
            return abi.encodePacked(uint8(0xff), uint64(num));
        }
    }

    /// @notice Checks the validity of schnorr signature
    /// @param _pubKeyX public key x-coordinate
    /// @param _hash msg hash that user signed
    /// @param _signature of the msg
    function _verifySchnorr(
        bytes32 _pubKeyX,
        bytes32 _hash,
        Signature memory _signature
    ) private pure returns (bool) {
        bytes32 sp = bytes32(Q - mulmod(uint256(_signature.s), uint256(_pubKeyX), Q));
        bytes32 ep = bytes32(Q - mulmod(uint256(_signature.r), uint256(_pubKeyX), Q));
        require(sp != 0, "TeleOrdinal: wrong sig");
        address R = ecrecover(sp, _signature.v, _pubKeyX, ep);
        require(R != address(0), "TeleOrdinal: ecrecover failed");
        return _signature.r
            == keccak256(abi.encodePacked(R, uint8(_signature.v), _pubKeyX, _hash));
    }

    /// @notice Returns a sliced bytes
    /// @param _data Data that is sliced
    /// @param _start Start index of slicing
    /// @param _end End index of slicing
    /// @return _result The result of slicing
    function _sliceBytes(
        bytes memory _data,
        uint _start,
        uint _end
    ) private pure returns (bytes memory _result) {
        bytes1 temp;
        for (uint i = _start; i <= _end; i++) {
            temp = _data[i];
            _result = abi.encodePacked(_result, temp);
        }
    }

    /// @notice Calculates bitcoin double hash function
    function _doubleHash(bytes memory _input) private pure returns(bytes memory) {
        bytes32 inputHash1 = sha256(_input);
        bytes20 inputHash2 = ripemd160(abi.encodePacked(inputHash1));
        return abi.encodePacked(inputHash2);
    }

    /// @notice Compare two bytes string
    function _compareBytes(bytes memory _a, bytes memory _b) private pure returns (bool) {
        return keccak256(_a) == keccak256(_b);
    }

    /// @notice Convert bytes with length 20 to address
    function _bytesToAddress(bytes memory _data) private pure returns (address) {
        require(_data.length == 20, "TeleOrdinal: Invalid len");
        address addr;
        assembly {
            addr := mload(add(_data, 20))
        }
        return addr;
    }

    /// @notice Convert bytes with length 32 to bytes32
    function _convertToBytes32(bytes memory _data) private pure returns (bytes32) {
        require(_data.length == 32, "TeleOrdinal: Invalid len");
        bytes32 result;
        assembly {
            result := mload(add(_data, 32))
        }
        return result;
    }
}