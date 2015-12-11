/*
 *   Copyright (c) Genetec Corporation. All Rights Reserved.
 */

package jp.cocodayo.

import jp.cocodayo.base.BusMod

import org.vertx.java.core.Future

class %file-without-ext% extends BusMod {

  def spec = [:]

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
