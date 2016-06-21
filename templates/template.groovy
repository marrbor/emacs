/*
 *   Copyright (c) Genetec Corporation. All Rights Reserved.
 */

package jp.cocodayo.

import io.vertx.core.Future
import io.vertx.lang.groovy.GroovyVerticle
import io.vertx.core.logging.LoggerFactory
import io.vertx.core.logging.Logger

public class %file-without-ext% extends GroovyVerticle {

  private Logger log = LoggerFactory.getLogger(%file-without-ext%.class)

  public void start(Future<Void> future) {
    log.info "Boot %file-without-ext%"
    vertx.deployVerticle("v.rb",
                         { res ->
                           if (res.succeeded()) {
                             future.complete()
                           } else {
                             future.fail()
                           }
                         })
  }

  public void stop(Future<Void> future) {
    log.info "Stop %file-without-ext%"
    future.complete()
  }
}
