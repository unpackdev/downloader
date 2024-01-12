//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.4;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./base64.sol";
import "./ISudoPair.sol";
import "./ISudoSwap.sol"; //factory

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

import "./SafeTransferLib.sol";

interface IRenderer {
    function render(uint256 id) external view returns (string calldata);

    function attributes(uint256 id) external view returns (string calldata);
}

contract Fourk3D is Ownable, ERC721iEnumerable, VRFConsumerBaseV2 {
    enum GAME_STATE {
        NOT_INITIALIZED,
        OPEN,
        WAITING_NUMBER,
        GOT_NUMBER,
        FINISHED
    }

    using SafeTransferLib for address payable;

    IRenderer public renderer;

    ISudoPair public sudoPool;

    ISudoSwap public sudoFactory;

    address public dev;

    uint256 public multiplier;

    GAME_STATE public currentState;

    bool public started;
    uint128 public burned;

    // CHAINLINK STUFF
    VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // Goerli coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;

    // 200 gwei Key Hash
    bytes32 keyHash =
        0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

    uint32 callbackGasLimit = 100000;

    uint16 requestConfirmations = 3;

    uint32 numWords = 1;

    uint256 public winningTicket;

    uint256 public s_requestId;

    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed fromAddress,
        address indexed toAddress
    );

    constructor(
        string memory name,
        string memory symbol,
        uint64 subscriptionId
    ) ERC721(name, symbol) VRFConsumerBaseV2(vrfCoordinator) {
        dev = 0xD95A9A47b3772a262262a5A14Fd9B0DA5cE5F0f7;
        sudoFactory = ISudoSwap(0xb16c1342E617A5B6E4b631EB114483FDB289c0A4);
        multiplier = 50;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
    }

    function setup(address _renderer) external onlyOwner {
        renderer = IRenderer(_renderer);
    }

    function mint() internal {
        if (_maxSupply == 0) {
            _preMintReceiver = address(sudoPool);
        }
        _balances[_preMintReceiver] += multiplier;
        _maxSupply = _maxSupply + multiplier;

        // Emit the Consecutive Transfer Event
        emit ConsecutiveTransfer(
            totalSupply() == multiplier ? 1 : _maxSupply - (multiplier - 1),
            _maxSupply,
            address(0),
            _preMintReceiver
        );
    }

    // set _preminter to sudo pool
    function initialize() external payable {
        require(currentState == GAME_STATE.NOT_INITIALIZED, "Game started");
        createPool();
        mint();
        currentState = GAME_STATE.OPEN;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        // if a user sells an nft we burn it and send him the eth
        if (to == address(sudoPool)) {
            // here we do chainlink stuff for winner
            if (
                _maxSupply - burned >= 4000 && currentState == GAME_STATE.OPEN
            ) {
                // add chainlink stuff
                currentState = GAME_STATE.WAITING_NUMBER;
                sudoPool.withdrawAllETH();
                requestRandomWords();
            } else if (currentState == GAME_STATE.GOT_NUMBER) {
                // here we distribute prize if we got number
                distributePrize(40);
            }

            burn(tokenId);
        }
        // if a user buys
        else if (from == address(sudoPool)) {
            if (
                balanceOf(address(sudoPool)) == 0 &&
                currentState == GAME_STATE.OPEN
            ) {
                //we mint more
                mint();
            }
        }
    }

    function burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        // Prevent re-assigning the token back to the Pre-Mint Receiver
        _owners[tokenId] = 0x000000000000000000000000000000000000dEaD;

        burned += 1;
        emit Transfer(owner, address(0), tokenId);
    }

    receive() external payable {}

    // pool for user to buy nfts
    function createPool() internal {
        address _sudoPair = sudoFactory.createPairETH(
            IERC721(address(this)),
            ICurve(0x432f962D8209781da23fB37b6B59ee15dE7d9841), // exponential curve
            payable(0x0), //   _assetRecipient .
            LSSVMPair.PoolType.TRADE, // pool type
            1001100000000000000, //delta  0.11%
            0, //fee
            0.01 ether, //starting price in eth 0.01
            new uint256[](0)
        );

        sudoPool = ISudoPair(_sudoPair);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string
            memory descr = "4K3D is an on chain Sudoswap game to test liquidity, a lucky holder can take home 700+ eth.";

        string memory image = renderer.render(_tokenId);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    (
                        Base64.encode(
                            bytes(
                                (
                                    abi.encodePacked(
                                        '{"name":"4K3D #',
                                        uint2str(_tokenId),
                                        '","image": ',
                                        '"',
                                        "data:image/svg+xml;base64,",
                                        Base64.encode(bytes(image)),
                                        '",',
                                        '"description":"',
                                        descr,
                                        '",',
                                        '"attributes":[]}'
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // this is an emergency function in the case of chainlink not working on the first call ,we call it again but shouldn't be a problem..
    function emergencyRandomness() external onlyOwner {
        require(
            currentState != GAME_STATE.GOT_NUMBER && _maxSupply - burned > 4000,
            "Forbidden"
        );
        currentState = GAME_STATE.WAITING_NUMBER;
        requestRandomWords();
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() internal {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        require(currentState == GAME_STATE.WAITING_NUMBER, "not goo state");
        winningTicket = randomWords[0];
        currentState = GAME_STATE.GOT_NUMBER;
    }

    // make this not fail
    function distributePrize(uint256 rounds) public {
        require(currentState == GAME_STATE.GOT_NUMBER, "not goo state");

        uint256 supply = totalSupply();
        uint256 i;
        unchecked {
            while (i < rounds) {
                address potentialWinner = _owners[(winningTicket + i) % supply];
                if (
                    potentialWinner != address(0) &&
                    potentialWinner != address(sudoPool)
                ) {
                    // we withdraw all eth into this contract
                    sudoPool.withdrawAllETH();

                    // send 10% to dave wallet
                    payable(dev).safeTransferETH(address(this).balance / 10);

                    // send rest to winner
                    payable(potentialWinner).safeTransferETH(
                        address(this).balance
                    );
                    // add state of game
                    currentState = GAME_STATE.FINISHED;
                    return;
                }
                i++;
            }
            winningTicket = winningTicket + i;
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        if (owner == address(_preMintReceiver)) {
            uint256 i = 1;
            uint256 supply = totalSupply();
            if (supply > 2 * multiplier) {
                i = supply - 2 * multiplier;
            }

            uint256 matched = 0;
            while (i < supply) {
                if (ownerOf(i) == address(_preMintReceiver)) {
                    matched += 1;
                    if (matched - 1 == index) {
                        return i;
                    }
                }
                i = i + 1;
            }
        } else {
            uint256 tokenId = _ownedTokens[owner][index];

            return tokenId;
        }
    }
}
