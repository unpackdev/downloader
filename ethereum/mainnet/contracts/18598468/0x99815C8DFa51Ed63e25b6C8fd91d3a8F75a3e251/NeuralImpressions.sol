// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

/**
 * @title: Muraqqa: Neural Impressions
 * @creator: @orkhan_art - orkhan mammadov
 * @author: @devbhang - devbhang.eth
 */

import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";
import "./ERC2981.sol";
import "./Ownable.sol";

/////////////////////////////////////////////////////
//                                                 //
//                                                 //
//   +-+ +-+ +-+ +-+ +-+ +-+                       //
//   |N| |E| |U| |R| |A| |L|                       //
//   +-+ +-+ +-+ +-+ +-+ +-+                       //
//                                                 //
//                                                 //
//   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+   //
//   |I| |M| |P| |R| |E| |S| |S| |I| |O| |N| |S|   //
//   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+   //
//                                                 //
//                                                 //
//   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+           //
//   |B| |Y| |:| |O| |R| |K| |H| |A| |N|           //
//   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+           //
//                                                 //
//                                                 //
/////////////////////////////////////////////////////

interface IERC721AQueryable {
    function tokensOfOwner(
        address owner
    ) external view returns (uint256[] memory);
}

contract NeuralImpressions is
    ERC721Enumerable,
    ERC721Pausable,
    Ownable,
    ERC2981
{
    uint256 public constant MAX_SUPPLY = 111;

    string public baseURI;
    address public treasuryAddress;

    IERC721AQueryable public muraqqaContract;

    mapping(uint256 => bool) public tokenMinted;

    constructor(
        address _address,
        uint96 _royalty,
        string memory _newBaseURI,
        address _muraqqaContract
    ) ERC721("Neural Impressions", "NIMP") Ownable(_address) {
        treasuryAddress = _address;
        baseURI = _newBaseURI;
        muraqqaContract = IERC721AQueryable(_muraqqaContract);

        _setDefaultRoyalty(_address, _royalty);
        _pause();
    }

    function setRoyalty(address _address, uint96 _royalty) external onlyOwner {
        treasuryAddress = _address;
        _setDefaultRoyalty(_address, _royalty);
    }

    function setMuraqqaContract(address _muraqqaContract) public onlyOwner {
        muraqqaContract = IERC721AQueryable(_muraqqaContract);
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getTokensOfOwner(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256 _balance = balanceOf(_owner);
        uint256[] memory _ids = new uint256[](_balance);

        for (uint i; i < _balance; i++) {
            _ids[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return _ids;
    }

    function getAvailableMints(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256[] memory _tokens = muraqqaContract.tokensOfOwner(_owner);

        uint256 _counter;

        for (uint i; i < _tokens.length; i++) {
            if (!tokenMinted[_tokens[i]]) {
                _counter++;
            }
        }

        uint256[] memory _ids = new uint256[](_counter);
        uint256 _index;

        for (uint i; i < _tokens.length; i++) {
            if (!tokenMinted[_tokens[i]]) {
                _ids[_index] = _tokens[i];
                _index++;
            }
        }

        return _ids;
    }

    function mintToken() external whenNotPaused {
        uint256[] memory _tokens = getAvailableMints(msg.sender);

        require(_tokens.length > 0, "NO AVAILABLE TOKENS");
        require(
            totalSupply() + _tokens.length <= MAX_SUPPLY,
            "MAX SUPPLY IS EXCEEDED"
        );

        for (uint i; i < _tokens.length; i++) {
            tokenMinted[_tokens[i]] = true;

            _safeMint(msg.sender, _tokens[i]);
        }
    }

    function mintAdmin(
        address _to,
        uint256[] calldata _tokens
    ) external onlyOwner {
        require(
            totalSupply() + _tokens.length <= MAX_SUPPLY,
            "MAX SUPPLY IS EXCEEDED"
        );

        for (uint i; i < _tokens.length; i++) {
            require(
                0 < _tokens[i] && _tokens[i] <= MAX_SUPPLY,
                "INVALID TOKEN ID"
            );
            require(!tokenMinted[_tokens[i]], "INVALID TOKEN ID");

            tokenMinted[_tokens[i]] = true;

            _safeMint(_to, _tokens[i]);
        }
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721Enumerable, ERC721Pausable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}