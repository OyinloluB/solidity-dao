// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

import "./Token.sol";

interface IToken {
    function balanceOf(address owner) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

contract Dao is Ownable {
    IToken public tokenContract;

    // events
    event SubmissionCreated(string name);
    event Vote(uint256 submissionId);
    event Unvote(uint256 submissionId);

    struct Submission {
        uint256 id;
        string name;
        uint256 voteCount;
        uint256 deadline;
    }

    mapping(uint256 => bool) voters;

    Submission[] public submissionsArr;

    mapping(uint256 => Submission) public submissions;

    uint256 public submissionCount;

    mapping(address => bool) public isVoter;

    constructor(address _tokenContract) payable {
        tokenContract = IToken(_tokenContract);
    }

    modifier tokenOwnerOnly() {
        require(
            tokenContract.balanceOf(msg.sender) > 0,
            "You don't own any tokens"
        );
        _;
    }

    modifier onlyActiveProposal(uint256 submissionId) {
        require(
            submissions[submissionId].deadline > block.timestamp,
            "This proposal is no longer active"
        );
        _;
    }

    function addSubmission(string memory _name) external tokenOwnerOnly {
        submissionCount++;
        Submission memory newSubmission = Submission(
            submissionCount,
            _name,
            0,
            block.timestamp + 5 minutes
        );

        submissionsArr.push(
            Submission(submissionCount, _name, 0, block.timestamp + 5 minutes)
        );

        submissions[submissionCount] = newSubmission;

        emit SubmissionCreated(_name);
    }

    function viewSubmission(uint256 _submissionId)
        external
        view
        returns (Submission memory submission)
    {
        return submissions[_submissionId];
    }

    function viewSubmissions()
        external
        view
        returns (Submission[] memory)
    {
        return submissionsArr;
    }

    function vote(uint256 _submissionId)
        external
        tokenOwnerOnly
        onlyActiveProposal(_submissionId)
    {
        uint256 numVotes = 0;

        if (voters[_submissionId] == false) {
            numVotes++;
            voters[_submissionId] = true;
        }

        require(numVotes > 0, "You cannot vote twice");

        isVoter[msg.sender] = true;
        submissions[_submissionId].voteCount++;

        emit Vote(_submissionId);
    }

    function viewVotes(uint256 _submissionId) public view returns (uint256) {
        return submissions[_submissionId].voteCount;
    }

    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}
}
