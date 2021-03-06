//
//  MCIMAPCheckAccountOperation.cc
//  mailcore2
//
//  Created by DINH Viêt Hoà on 1/12/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include "MCIMAPCheckAccountOperation.h"

#include "MCIMAPAsyncConnection.h"
#include "MCIMAPSession.h"

using namespace mailcore;

IMAPCheckAccountOperation::IMAPCheckAccountOperation()
{
    mLoginResponse = NULL;
}

IMAPCheckAccountOperation::~IMAPCheckAccountOperation()
{
    MC_SAFE_RELEASE(mLoginResponse);
}

void IMAPCheckAccountOperation::main()
{
    ErrorCode error;
    session()->session()->connectIfNeeded(&error);
    if (error == ErrorNone) {
        session()->session()->login(&error);
        if (error != ErrorNone) {
            MC_SAFE_REPLACE_COPY(String, mLoginResponse, session()->session()->loginResponse());
        }
    }
    setError(error);
}

String * IMAPCheckAccountOperation::loginResponse()
{
    return mLoginResponse;
}
