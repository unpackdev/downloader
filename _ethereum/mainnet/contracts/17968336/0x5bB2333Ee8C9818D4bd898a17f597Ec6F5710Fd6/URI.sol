// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";

/// @title BLONKS URI Shapeshifter Contract v3.0.0
/// @author Matto AKA MonkMatto
/// @notice This contract manages BLONKS token image and metadata generation.
/// @dev This contract allows EVM renderer changes.
/// @custom:security-contact monkmatto@protonmail.com

interface iBLONKSmain {
    function ownerOf(uint256 _tokenId) external view returns (address);

    function tokenEntropyMap(uint256 _tokenId) external view returns (uint256);
}

interface iBLONKStraits {
    function calculateTraitsArray(
        uint256 _tokenEntropy
    ) external view returns (uint8[11] memory);

    function calculateTraitsJSON(
        uint8[11] memory _traitsArray
    ) external view returns (string memory);
}

interface iBLONKSlocations {
    function calculateLocatsArray(
        uint256 _ownerEntropy,
        uint256 _tokenEntropy,
        uint8[11] memory _traitsArray
    ) external view returns (uint16[110] memory);
}

interface iBLONKSsvg {
    function assembleSVG(
        uint256 _ownerEntropy,
        uint256 _tokenEntropy,
        uint8[11] memory _traitsArray,
        uint16[110] memory _locatsArray
    ) external view returns (string memory);
}

interface iBLONKSdescriptions {
    function buildDynamicDescription(
        address _ownerAddy,
        uint256 _shapeshiftCount,
        string memory _collectionDescription,
        string memory _shifterName,
        uint256 _shifterActive,
        uint256 _shifterMax
    ) external view returns (string memory);
}

interface iDelegate {
    function checkDelegateForContract(
        address _delegate,
        address _vault,
        address _contract
    ) external view returns (bool);
}

contract BLONKSuri is Ownable {
    using Counters for Counters.Counter;
    using Strings for string;

    address private constant mainContract =
        0x7f463b874eC264dC7BD8C780f5790b4Fc371F11f;
    address private constant delegateContract =
        0x00000000000076A84feF008CDAbe6409d2FE638B;
    address private descriptionsContract;

    struct Shapeshifter {
        address traits;
        address locats;
        address svg;
        string name;
        uint16 max;
        uint16 active;
        bool openToAll;
    }

    Shapeshifter[] public Shapeshifters;
    string public artistNameOverride;
    mapping(uint256 => uint256) public shifterStateMap;
    mapping(uint256 => uint256) public idMap;
    mapping(uint256 => bool) private idSetMap;
    mapping(uint256 => bool) public tokenStateLock;
    mapping(uint256 => string) public uniqueNameMap;
    mapping(uint256 => mapping(uint256 => uint256)) public tokenShiftCounts;
    bool public shapeshiftingAllowed;

    event Shapeshift(uint256 indexed _tokenId, uint256 _state);

    event NewShapeshifter(
        address _traits,
        address _locations,
        address _svg,
        string _name,
        uint16 _max,
        bool _openToAll
    );

    function SHAPESHIFT(uint256 _tokenId, uint256 _state) external {
        address ownerAddy = iBLONKSmain(mainContract).ownerOf(_tokenId);
        require(shapeshiftingAllowed == true, "Shapeshifting is paused");
        require(
            ownerAddy == msg.sender ||
                iDelegate(delegateContract).checkDelegateForContract(
                    msg.sender,
                    ownerAddy,
                    mainContract
                ) ||
                msg.sender == owner(),
            "Not authorized"
        );
        require(_state < Shapeshifters.length, "Shapeshifter out of range");
        require(
            Shapeshifters[_state].active < Shapeshifters[_state].max,
            "Shapeshift max reached"
        );
        bool isOpenShifter = Shapeshifters[_state].openToAll;
        require(isOpenShifter || msg.sender == owner(), "Not authorized");
        require(tokenStateLock[_tokenId] == false, "Token is locked");
        if (!isOpenShifter) {
            tokenStateLock[_tokenId] = true;
        }
        if (idSetMap[_tokenId] == false) {
            idSetMap[_tokenId] = true;
            idMap[
                iBLONKSmain(mainContract).tokenEntropyMap(_tokenId)
            ] = _tokenId;
        }
        Shapeshifters[shifterStateMap[_tokenId]].active--;
        Shapeshifters[_state].active++;
        shifterStateMap[_tokenId] = _state;
        tokenShiftCounts[_tokenId][_state]++;
        emit Shapeshift(_tokenId, _state);
    }

    function addShapeshifter(
        address _traits,
        address _locations,
        address _svg,
        string memory _name,
        uint16 _max,
        bool _openToAll
    ) external onlyOwner {
        uint16 _active;
        if (Shapeshifters.length == 0) {
            _active = 4444;
        }
        Shapeshifters.push(
            Shapeshifter(
                _traits,
                _locations,
                _svg,
                _name,
                _max,
                _active,
                _openToAll
            )
        );
        emit NewShapeshifter(
            _traits,
            _locations,
            _svg,
            _name,
            _max,
            _openToAll
        );
    }

    function addUniqueName(
        uint256 _tokenId,
        string memory _name
    ) external onlyOwner {
        require(tokenStateLock[_tokenId] == true, "Token is not locked");
        uniqueNameMap[_tokenId] = _name;
    }

    function getShapeshiftAvailability()
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory available = new uint256[](Shapeshifters.length);
        for (uint256 i = 0; i < available.length; i++) {
            available[i] = (Shapeshifters[i].max - Shapeshifters[i].active);
        }
        return available;
    }

    function getTokenShapeshiftTotals(
        uint256 _tokenId
    ) public view returns (uint256) {
        uint256 totals;
        for (uint256 i = 0; i < Shapeshifters.length; i++) {
            totals += tokenShiftCounts[_tokenId][i];
        }
        return totals;
    }

    function buildMetaPart(
        uint256 _tokenId,
        string memory _collectionDescription,
        address _artistAddy,
        uint256 _royaltyBps,
        string memory _collection,
        string memory _website,
        string memory _externalURL
    ) external view virtual returns (string memory) {
        string memory _name;
        if (tokenStateLock[_tokenId] == false) {
            _name = Shapeshifters[shifterStateMap[_tokenId]].name;
        } else {
            _name = uniqueNameMap[_tokenId];
        }

        uint256 state = shifterStateMap[_tokenId];
        string memory tokenDescription = iBLONKSdescriptions(
            descriptionsContract
        ).buildDynamicDescription(
                iBLONKSmain(mainContract).ownerOf(_tokenId),
                getTokenShapeshiftTotals(_tokenId),
                _collectionDescription,
                Shapeshifters[state].name,
                Shapeshifters[state].active,
                Shapeshifters[state].max
            );

        string memory metaP = string(
            abi.encodePacked(
                '{"name":"',
                _name,
                ' #',
                Strings.toString(_tokenId),
                '","artist":"',
                artistNameOverride,
                '","description":"',
                tokenDescription,
                '","royaltyInfo":{"artistAddress":"',
                Strings.toHexString(uint160(_artistAddy), 20),
                '","royaltyFeeByID":',
                Strings.toString(_royaltyBps / 100),
                '},"collection_name":"',
                _collection,
                '","website":"',
                _website,
                '","external_url":"',
                _externalURL,
                '","script_type":"Solidity","image_type":"Generative SVG","image":"data:image/svg+xml;base64,'
            )
        );
        return metaP;
    }

    function buildContractURI(
        string memory _collectionDescription,
        string memory _externalURL,
        uint256 _royaltyBps,
        address _artistAddy,
        string memory _svg
    ) external view virtual returns (string memory) {
        string memory b64svg = Base64.encode(bytes(_svg));
        string memory contractURI = string(
            abi.encodePacked(
                '{"name":"BLONKS","description":"',
                _collectionDescription,
                '","image":"data:image/svg+xml;base64,',
                b64svg,
                '","external_link":"',
                _externalURL,
                '","royalty_basis_points":',
                Strings.toString(_royaltyBps),
                ',"royalty_recipient":"',
                Strings.toHexString(uint160(_artistAddy), 20),
                '"}'
            )
        );
        return contractURI;
    }

    function getLegibleTokenURI(
        string memory _metaP,
        uint256 _tokenEntropy,
        uint256 _ownerEntropy
    ) external view virtual returns (string memory) {
        uint256 _state = shifterStateMap[idMap[_tokenEntropy]];
        uint8[11] memory traitsArray = iBLONKStraits(
            Shapeshifters[_state].traits
        ).calculateTraitsArray(_tokenEntropy);
        _tokenEntropy /= 10 ** 18;
        string memory traitsJSON = iBLONKStraits(Shapeshifters[_state].traits)
            .calculateTraitsJSON(traitsArray);
        uint16[110] memory locatsArray = iBLONKSlocations(
            Shapeshifters[_state].locats
        ).calculateLocatsArray(_ownerEntropy, _tokenEntropy, traitsArray);
        _ownerEntropy /= 10 ** 29;
        _tokenEntropy /= 10 ** 15;
        string memory svg = iBLONKSsvg(Shapeshifters[_state].svg).assembleSVG(
            _ownerEntropy,
            _tokenEntropy,
            traitsArray,
            locatsArray
        );
        string memory legibleURI = string(
            abi.encodePacked(
                _metaP,
                Base64.encode(bytes(svg)),
                '",',
                traitsJSON,
                "}"
            )
        );
        return legibleURI;
    }

    function buildPreviewSVG(
        uint256 _tokenEntropy,
        uint256 _addressEntropy
    ) external view virtual returns (string memory) {
        return
            _renderSVG(
                _tokenEntropy,
                _addressEntropy,
                shifterStateMap[idMap[_tokenEntropy]]
            );
    }

    function _renderSVG(
        uint256 _tokenEntropy,
        uint256 _addressEntropy,
        uint256 _state
    ) internal view returns (string memory) {
        uint8[11] memory traitsArray = iBLONKStraits(
            Shapeshifters[_state].traits
        ).calculateTraitsArray(_tokenEntropy);
        _tokenEntropy /= 10 ** 18;
        uint16[110] memory locatsArray = iBLONKSlocations(
            Shapeshifters[_state].locats
        ).calculateLocatsArray(_addressEntropy, _tokenEntropy, traitsArray);
        _addressEntropy /= 10 ** 29;
        _tokenEntropy /= 10 ** 15;
        string memory svg = iBLONKSsvg(Shapeshifters[_state].svg).assembleSVG(
            _addressEntropy,
            _tokenEntropy,
            traitsArray,
            locatsArray
        );
        return svg;
    }

    function RANDOM_RENDER_SVG(
        uint256 _state
    ) public view returns (string memory) {
        uint256 _tokenEntropy = uint256(
            keccak256(
                abi.encodePacked(blockhash(block.number - 1), block.basefee)
            )
        );
        uint256 _addressEntropy = uint256(
            uint160(
                uint256(
                    keccak256(abi.encodePacked(block.coinbase, block.timestamp))
                )
            )
        );
        return _renderSVG(_tokenEntropy, _addressEntropy, _state);
    }

    function RANDOM_RENDER_B64(
        uint256 _state
    ) external view returns (string memory) {
        string memory svg = RANDOM_RENDER_SVG(_state);
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(svg))
                )
            );
    }

    function PREVIEW_SHAPESHIFTER_SVG(
        uint256 _tokenId,
        address _addy,
        uint256 _state
    ) public view returns (string memory) {
        require(_state < Shapeshifters.length, "Shapeshifter out of range");
        return
            _renderSVG(
                iBLONKSmain(mainContract).tokenEntropyMap(_tokenId),
                uint256(uint160(_addy)),
                _state
            );
    }

    function PREVIEW_SHAPESHIFTER_B64(
        uint256 _tokenId,
        address _addy,
        uint256 _state
    ) external view returns (string memory) {
        string memory svg = PREVIEW_SHAPESHIFTER_SVG(_tokenId, _addy, _state);
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(svg))
                )
            );
    }

    function getBase64TokenURI(
        string memory _legibleURI
    ) external view virtual returns (string memory) {
        string memory URIBase64 = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(_legibleURI))
            )
        );
        return URIBase64;
    }

    function setArtistNameOverride(
        string memory _artistNameOverride
    ) external onlyOwner {
        artistNameOverride = _artistNameOverride;
    }

    function setDescriptionsContract(
        address _descriptionsContract
    ) external onlyOwner {
        descriptionsContract = _descriptionsContract;
    }

    function updateShapeshifter(
        uint256 _state,
        address _traits,
        address _locats,
        address _svg,
        string memory _name,
        uint16 _max,
        uint16 _active,
        bool _openToAll
    ) external onlyOwner {
        require(shapeshiftingAllowed == false, "Shapeshifter setting allowed");
        Shapeshifter storage shapeshifter = Shapeshifters[_state];
        shapeshifter.traits = _traits;
        shapeshifter.locats = _locats;
        shapeshifter.svg = _svg;
        shapeshifter.name = _name;
        shapeshifter.max = _max;
        shapeshifter.active = _active;
        shapeshifter.openToAll = _openToAll;
    }

    function toggleShapeshiftingAllowed() external onlyOwner {
        shapeshiftingAllowed = !shapeshiftingAllowed;
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        uint256 encodedLen = 4 * ((len + 2) / 3);
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}
