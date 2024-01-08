//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./console.sol";
import "./base64.sol";


interface IGas is IERC721 {
  function svg(uint256 id) external view returns (string memory);
}

contract WrappedNFGas is ERC721, IERC721Receiver, Ownable {

  IGas private nfGas;

  constructor(address _nfgasContract) ERC721("Wrapped NFGas", "WNFG")
  {
    nfGas = IGas(_nfgasContract);
  }

  // Mint a new one when receiving an NFGas
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) public override returns (bytes4) {
    if (msg.sender != address(nfGas)) {
      return "";
    }
    _safeMint(from, tokenId);
    return IERC721Receiver.onERC721Received.selector;
  }

  function burn(uint256 gasIdx)  public
  {
    require(_isApprovedOrOwner(msg.sender, gasIdx), "not owner nor approved");
    _burn(gasIdx);
    nfGas.safeTransferFrom(address(this), msg.sender, gasIdx);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "nonexistent token");
    return constructTokenURI(tokenId);
  }

  // if a token gets stuck here due to unsafe transfer being used, allow admin to assign it.
  function saveToken(uint256 tokenId, address newOwner) onlyOwner public {
      require(nfGas.ownerOf(tokenId) == address(this), "not lost");
      // ensure the token does not exist yet
      _safeMint(newOwner, tokenId);
  }

  function constructTokenURI(uint256 gasIdx) public view returns (string memory) {
    string memory name = string(abi.encodePacked('NFGas #', uint2str(gasIdx)));
    string memory description = string(abi.encodePacked('An NFT corresponding to the gas price of ', uint2str(gasIdx), ' gwei.'));
    string memory svg = Base64.encode(bytes(nfGas.svg(gasIdx)));

    return
        string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', name,
                            '", "description":"', description,
                            '", "image": "',
                            'data:image/svg+xml;base64,',
                            svg,
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}