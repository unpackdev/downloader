//SPDX-License-Identifier: WTFPL v6.9
pragma solidity >0.8.0;

import "./Interface.sol";
import "./Util.sol";

/**
 * @title BENSYC CCIP
 */

abstract contract Clone {
    iBENSYC public BENSYC;
    iENS public ENS;

    // @dev : re-entrancy protectoooor
    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }

    /**
     * @dev : withdraw ether only to Dev (or multi-sig)
     */
    function withdrawEther() external {
        require(msg.sender == BENSYC.Dev());
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev : to be used in case some tokens get locked in the contract
     * @param _token : token to release
     * @param _bal : amount to release
     */
    function withdrawToken(address _token, uint256 _bal) external {
        require(msg.sender == BENSYC.Dev());
        iToken(_token).transferFrom(address(this), msg.sender, _bal);
    }
}

contract XCCIP is Clone {
    bytes32 public immutable secondaryDomainHash; // ENS namehash of "bensyc.eth"
    bytes32 public immutable baseHash; // ens namehash of ".eth"
    bytes32 public immutable primaryDomainHash; // ENS namehash of "boredensyachtclub.eth"

    /// @dev : CCIP https://eips.ethereum.org/EIPS/eip-3668
    error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);

    error InvalidTokenID(string id, uint256 index);
    error InvalidParentDomain(string str);
    error InvalidNamehash(bytes32 expected, bytes32 provided);
    error RequestError(bytes32 expected, bytes32 check, bytes data, uint256 blknum, bytes result);
    error StaticCallFailed(address resolver, bytes _call, bytes _error);
    error ResolverNotSet(bytes32 node, bytes data);

    function supportsInterface(bytes4 sig) external pure returns (bool) {
        return (sig == XCCIP.resolve.selector || sig == XCCIP.supportsInterface.selector);
    }

    constructor(address _bensyc) {
        baseHash = keccak256(abi.encodePacked(bytes32(0), keccak256("eth")));
        secondaryDomainHash = keccak256(abi.encodePacked(baseHash, keccak256(bytes("bensyc"))));
        primaryDomainHash = keccak256(abi.encodePacked(baseHash, keccak256(bytes("boredensyachtclub"))));
        BENSYC = iBENSYC(_bensyc);
        ENS = iENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    }

    /**
     * @dev : dnsDecode()
     * @param name : name
     */
    function dnsDecode(bytes calldata name) public view returns (bytes32, bool) {
        uint256 i;
        uint256 j;
        bytes[] memory labels = new bytes[](4);
        uint256 len;
        while (name[i] != 0x0) {
            unchecked {
                len = uint8(bytes1(name[i:++i]));
                labels[j] = name[i:i += len];
                ++j;
            }
        }

        i = 0;
        for (j = 0; j < labels[0].length;) {
            if (labels[0][j] < 0x30 || labels[0][j] > 0x39) {
                return (keccak256(labels[0]), false);
            }
            unchecked {
                i = (i * 10) + (uint8(labels[0][j]) - 48);
                ++j;
            }
        }
        if (i >= BENSYC.totalSupply()) {
            revert InvalidTokenID(string(labels[0]), 10_000);
        }
        return (keccak256(labels[0]), true);
    }

    /**
     * @dev : resolve()
     * @param name : name
     * @param data : data
     */
    function resolve(bytes calldata name, bytes calldata data) external view returns (bytes memory) {
        bytes32 _callhash;
        bool isNFT;
        if (bytes32(data[4:36]) == secondaryDomainHash) {
            _callhash = primaryDomainHash;
        } else {
            (_callhash, isNFT) = dnsDecode(name);
            _callhash =
                isNFT
                ? keccak256(abi.encodePacked(primaryDomainHash, _callhash))
                : keccak256(abi.encodePacked(baseHash, _callhash));
        }

        bytes memory _result = getResult(_callhash, data);
        string[] memory _urls = new string[](2);
        _urls[0] = 'data:text/plain,{"data":"{data}"}';
        _urls[1] = 'data:application/json,{"data":"{data}"}';
        revert OffchainLookup(
            address(this),
            _urls,
            _result, // {data} field
            XCCIP.resolveWithoutProof.selector,
            abi.encode(keccak256(abi.encodePacked(msg.sender, address(this), data, block.number, _result)), block.number, data)
        );
    }

    /**
     * @dev : getResult()
     * @param _callhash : _callhash
     * @param data : data
     */
    function getResult(bytes32 _callhash, bytes calldata data) public view returns (bytes memory) {
        bytes memory _call =
            (data.length > 36) ? abi.encodePacked(data[:4], _callhash, data[36:]) : abi.encodePacked(data[:4], _callhash);

        address _resolver = ENS.resolver(_callhash);
        if (_resolver == address(0)) {
            revert ResolverNotSet(_callhash, _call);
        }
        (bool ok, bytes memory _result) = _resolver.staticcall(_call);
        if (!ok) {
            revert StaticCallFailed(_resolver, _call, _result);
        }
        return _result;
    }

    /**
     * Callback used by CCIP read compatible clients to verify and parse the response.
     */
    function resolveWithoutProof(bytes calldata response, bytes calldata extraData)
        external
        view
        returns (bytes memory)
    {
        (bytes32 hash, uint256 blknum, bytes memory data) = abi.decode(extraData, (bytes32, uint256, bytes));
        bytes32 check = keccak256(abi.encodePacked(msg.sender, address(this), data, blknum, response));
        if (check != hash || block.number > blknum + 5) {
            // extra check
            revert RequestError(hash, check, data, blknum, response);
        }
        return response;
    }
}
