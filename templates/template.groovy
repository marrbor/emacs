/*
 *   Copyright (c) Genetec Corporation. All Rights Reserved.
 */

package jp.cocodayo.

import jp.survei.base.BusMod

import org.vertx.java.core.Future

import groovy.transform.CompileStatic
import groovy.transform.TypeCheckingMode

// use @CompileStatic(TypeCheckingMode.SKIP) for method includes dynamic contents.

@CompileStatic
class %file-without-ext% extends BusMod {

  Map spec = [:]

  @Override def start(Future<Void> sr) {
    super.start()
    info "Boot %file-without-ext%"
    def confresult = chkconfig(config, spec)   // verify configuration.
    debug "chkconfig returns ${confresult}."
    if (confresult) sr.setFailure(confresult) // something wrong.
    else {
      info "Start %file-without-ext%"
      sr.setResult(null)
    }
  }

  @Override def stop() {
    info "%file-without-ext% Stopped."
  }
}
