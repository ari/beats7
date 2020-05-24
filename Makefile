# Created by: Palle Girgensohn <girgen@FreeBSD.org>
# $FreeBSD: head/sysutils/beats/Makefile 521867 2020-01-02 18:56:15Z glewis $

PORTNAME=	beats
PORTVERSION=	7.6.2
DISTVERSIONPREFIX=v
CATEGORIES=	sysutils
PKGNAMESUFFIX?=	7
CONFLICTS_INSTALL= zstd

MAINTAINER=	elastic@FreeBSD.org
COMMENT=	Send logs, network, heartbeat and system data to elasticsearch or logstash

LICENSE=	APACHE20

CONFLICTS=	beats

USES=		gmake go
USE_GITHUB=	yes
GH_ACCOUNT=	elastic
USE_RC_SUBR=	${GO_TARGETS}

GO_PKGNAME=	github.com/${GH_ACCOUNT}/${GH_PROJECT}
FIND_ARGS=	"! ( -regex .*/*\.(go|in|log) ) ! -path *test* ! -path *vendor*"
MAKE_ENV+=	GOBUILD_FLAGS=""

OPTIONS_DEFAULT=FILEBEAT HEARTBEAT METRICBEAT 
OPTIONS_DEFINE=	FILEBEAT HEARTBEAT METRICBEAT AUDITBEAT PACKETBEAT
OPTIONS_SUB=	yes

FILEBEAT_DESC=	Filebeat
FILEBEAT_VARS=	GO_TARGETS+=filebeat

PACKETBEAT_DESC=Packetbeat
PACKETBEAT_VARS=GO_TARGETS+=packetbeat
#PACKETBEAT_BROKEN=	An underlying library is currently broken under FreeBSD

METRICBEAT_DESC=Metricbeat
METRICBEAT_VARS=GO_TARGETS+=metricbeat

HEARTBEAT_DESC=	Heartbeat
HEARTBEAT_VARS=	GO_TARGETS+=heartbeat

AUDITBEAT_DESC=	Auditbeat
AUDITBEAT_VARS=	GO_TARGETS+=auditbeat

.include <bsd.port.options.mk>

do-build:
.for GO_TARGET in ${GO_TARGETS}
	@(cd ${GO_WRKSRC}; ${SETENV} ${MAKE_ENV} ${GO_ENV} ${GMAKE} -C ${GO_TARGET})
.endfor

do-install:
	${MKDIR} ${STAGEDIR}${ETCDIR}
.for BEATMOD in ${GO_TARGETS}
	${MKDIR} ${STAGEDIR}/var/db/beats/${BEATMOD}
	${INSTALL_PROGRAM} ${GO_WRKSRC}/${BEATMOD}/${BEATMOD} ${STAGEDIR}${PREFIX}/sbin
	${INSTALL_DATA} ${WRKSRC}/${BEATMOD}/${BEATMOD}.yml ${STAGEDIR}${ETCDIR}/${BEATMOD}.yml.sample
	(KIBANA_PATH=${STAGEDIR}${DATADIR}/${BEATMOD}/kibana; \
	        ${MKDIR} $${KIBANA_PATH}; \
	        DASHBOARD_FIND_ARGS="-path */_meta/kibana -type d"; \
		DASHBOARD_PATHS=$$(${SETENV} ${FIND} ${WRKSRC}/${BEATMOD} $${DASHBOARD_FIND_ARGS}); \
		for DASHBOARD_FILE in $${DASHBOARD_PATHS}; \
		do \
			(cd $${DASHBOARD_FILE} && ${COPYTREE_SHARE} . $${KIBANA_PATH}); \
		done)
.endfor
.for BEATMOD in filebeat metricbeat
	${MKDIR} ${STAGEDIR}${ETCDIR}/${BEATMOD}.modules.d ${STAGEDIR}${DATADIR}/${BEATMOD}/module
	(cd ${WRKSRC}/${BEATMOD}/module && ${COPYTREE_SHARE} . ${STAGEDIR}${DATADIR}/${BEATMOD}/module ${FIND_ARGS})
	(cd ${WRKSRC}/${BEATMOD}/modules.d && ${COPYTREE_SHARE} . ${STAGEDIR}${ETCDIR}/${BEATMOD}.modules.d)
.endfor
.for BEATMOD in auditbeat
	${MKDIR} ${STAGEDIR}${DATADIR}/${BEATMOD}/module
	(cd ${WRKSRC}/${BEATMOD}/module && ${COPYTREE_SHARE} . ${STAGEDIR}${DATADIR}/${BEATMOD}/module ${FIND_ARGS})
.endfor

.include <bsd.port.mk>
