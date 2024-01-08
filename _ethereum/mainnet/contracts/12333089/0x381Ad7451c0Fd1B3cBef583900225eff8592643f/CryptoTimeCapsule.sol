// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./console.sol";

import "./ERC20.sol";

contract CryptoTimeCapsule is ERC20 {

    uint256 constant maxIssue = 1000000*10**18;
    uint256 constant minVote = 1*10**18;
    uint256 constant basePrice = 2500*10**18; //1 ETH = 2000 TCV

    struct Post {
        uint256 postId;
        string  title;
        string  body;
        address owner;
        uint256 whenPosted;
        uint256 upVotes;
        uint256 downVotes;
    }

    address payable owner;
    Post[] public posts;

    constructor() 
        ERC20("Time Capsule Vote", "TCV")
    {
        owner = payable(msg.sender);
        _mint(owner, maxIssue);
    }

    function newPost(string memory _title, string memory _body, uint256 _votes) public {
        require(balanceOf(msg.sender) >= _votes, "Insufficient balance");
        require(_votes >= minVote, "At least 1 TCV required");
        Post memory post = Post(
            posts.length,
            _title,
            _body,
            msg.sender,
            block.timestamp,
            _votes,
            0
        );
        posts.push(post);
        _burn(msg.sender, _votes);
        //console.log("new post with id %s", post.id);
    }

    function getPost(uint256 _postId) public view returns(Post memory post) {
        require(posts[_postId].upVotes > 0, "Invalid post id");
        return posts[_postId];
    }

    function getAllPosts() public view returns(Post[] memory allPosts) {
        return posts;
    }

    function voteUp(uint256 _postId, uint256 _votes) public {
        require(balanceOf(msg.sender) >= _votes, "Insufficient balance");
        require(posts[_postId].upVotes > 0, "Invalid post id");
        posts[_postId].upVotes = posts[_postId].upVotes + _votes;
        _burn(msg.sender, _votes);
    }

    function voteDown(uint256 _postId, uint256 _votes) public {
        require(balanceOf(msg.sender) >= _votes, "Insufficient balance");
        require(posts[_postId].upVotes > 0, "Invalid post id");
        posts[_postId].downVotes = posts[_postId].downVotes + _votes;
        _burn(msg.sender, _votes);
    }

    function getUnsoldBalance() public view returns(uint256 unsoldCount) {
        return balanceOf(owner);
    }

    event Received(address, uint);
    receive() external payable {
        // uint256 maxIssue = 1000000*10**18;
        // uint256 basePrice = 2000*10**18; //1 ETH = 2000 TCV
        emit Received(msg.sender, msg.value);
        require(msg.value > 0);
        uint256 remainingVotes = balanceOf(owner);
        require(balanceOf(owner) > 0, "All TCV already sold");
        uint256 weiSent = msg.value; // Calculate tokens to sell
        uint256 votesBought = (weiSent * basePrice) / (1 ether);
        uint256 returnWei = 0;

        // console.log("Wei received:  %s", weiSent);
        // console.log("TCV requested: %s", votesBought);
        // console.log("TCV remaining: %s", remainingVotes);

        // if not enough votes left, update with what remains
        if(votesBought > remainingVotes){
            //get the cost to buy all the remaining votes
            uint256 newWeiCost = (remainingVotes/ basePrice) * (1 ether);
            //calc the refund amount
            returnWei = weiSent - newWeiCost;
            //update order
            weiSent = newWeiCost;
            votesBought = remainingVotes;
        }

        // console.log("Wei spent   :  %s", weiSent);
        // console.log("Wei returned:  %s", returnWei);

        if(returnWei > 0){
            payable(msg.sender).transfer(returnWei);
            emit Transfer(address(this), msg.sender, returnWei);
        }

        //transfer votes to sender
        _transfer(owner, msg.sender, votesBought);
        // console.log("TCV transfered:%s", votesBought);
        // console.log("TCV remaining: %s", balanceOf(owner));
        //transfer wei to contract owner
        owner.transfer(weiSent);
    }
}